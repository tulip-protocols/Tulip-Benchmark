use std::collections::BTreeMap;
use std::fs::{self, File};
use std::path::Path;

use capstone::Capstone;
use failure::Error;
use rida::{Type, IDA};
use serde_json;
use tempfile;

use image::arch::{Arch, Bits, Endian};
use image::function::Function;
use image::segment::Segments;
use image::Image;

use arch::arm::Block as ArmBlock;
use image::block::Block;

use loader;

macro_rules! PYLOADER { ($e:expr) => (format!(r#"
from idaapi import *
from idautils import *
import idc

import base64
import json

# Adapted from keystone; see: https://github.com/keystone-engine/keypatch/blob/bfcaef11de3a90efb08ed4f0c39dccf40d5613d0/keypatch.py
def get_meta():
    binary_info = dict()

    # heuristically detect hardware setup
    cpuname = idaapi.inf_get_procname().lower()

    binary_info["bits"] = "Bits64" if idaapi.inf_is_64bit() else "Bits32"
    binary_info["endian"] = "Big" if idaapi.inf_is_be() else "Little"

    if cpuname.startswith("arm"):
        binary_info["arch"] = "Arm"
    elif cpuname.startswith("mips"):
        binary_info["arch"] = "Mips"
    else:
        binary_info["arch"] = "NotSupported"

    return binary_info


auto_wait()

image = get_meta()
image["segments"] = []
image["functions"] = []

for ea in Segments():
    seg = dict()
    seg["name"] = idc.get_segm_name(ea)
    seg["start_addr"] = get_segm_start(ea)
    seg["end_addr"] = get_segm_end(ea)

    # Handle case of, e.g., .bss in IDA giving None for get_bytes()
    try:
        seg["bytes"] = get_bytes(
            idc.get_segm_start(ea), idc.get_segm_end(ea) - idc.get_segm_start(ea)
        )
    except:
        seg["bytes"] = ""

    assert type(seg["bytes"]) == bytes
    b = base64.b64encode(seg["bytes"])
    seg["bytes"] = b.decode("utf-8")

    image["segments"].append(seg)

    for fn_entry_address in Functions(idc.get_segm_start(ea), idc.get_segm_end(ea)):
        fn_name = get_func_name(fn_entry_address)
        fn = get_func(fn_entry_address)

        inst = dict()
        inst["name"] = fn_name
        inst["start_addr"] = fn.start_ea
        inst["end_addr"] = fn.end_ea
        inst["blocks"] = []

        for fn_block in FlowChart(fn):
            block = dict()
            block["start_addr"] = fn_block.start_ea
            block["end_addr"] = fn_block.end_ea
            block["t_reg"] = idc.get_sreg(fn_block.start_ea, "T") == 1
            block["dests"] = []

            for block_succ in fn_block.succs():
                block["dests"].append(block_succ.start_ea)

            inst["blocks"].append(block)

        image["functions"].append(inst)


with open("{}", "w+") as f:
    json.dump(image, f)
qexit(0)
"#, $e)) }

pub struct Loader(IDA);

#[derive(Debug, Deserialize)]
struct ImageRaw {
    arch: Arch,
    bits: Bits,
    endian: Endian,
    segments: Segments,
    functions: Vec<FunctionRaw>,
}

#[derive(Debug, Deserialize)]
struct FunctionRaw {
    name: String,
    start_addr: u64,
    end_addr: u64,
    blocks: Vec<BlockRaw>,
}

#[derive(Debug, Deserialize)]
struct BlockRaw {
    start_addr: u64,
    end_addr: u64,
    t_reg: bool, // For ARM
    dests: Vec<u64>,
}

impl Loader {
    pub fn new(ida_path: &str) -> Result<Loader, Error> {
        Ok(Loader(IDA::new(ida_path)?.script_type(Type::Python)))
    }

    fn lift_function(img: &Image, f: FunctionRaw, dis: &mut Capstone) -> Result<Function, Error> {
        let bvs = f.blocks.into_iter();
        let mut blocks = BTreeMap::new();

        for bv in bvs {
            let data = img.segments.get_bytes(bv.start_addr, bv.end_addr)?;
            let block = match img.arch {
                Arch::Arm => {
                    ArmBlock::new(bv.start_addr, bv.end_addr, bv.dests, bv.t_reg, data, dis)?
                        .into_boxed()
                }
                _ => {
                    unimplemented!()
                }
            };
            blocks.insert(bv.start_addr, block);
        }

        Ok(Function {
            name: f.name,
            start_addr: f.start_addr,
            end_addr: f.end_addr,
            blocks,
        })
    }
}

impl loader::Loader for Loader {
    fn load<P: AsRef<Path>>(&self, p: P) -> Result<Image, Error> {
        let json = tempfile::Builder::new().suffix("json").tempfile()?;

        let json_path = json.into_temp_path();

        self.0.run(
            &PYLOADER!(json_path.display()),
            p.as_ref().to_str().unwrap(),
        )?;

        let json = File::open(&json_path)?;

        let raw = serde_json::from_reader::<_, ImageRaw>(&json)?;

        let mut image = Image {
            arch: raw.arch,
            bits: raw.bits,
            endian: raw.endian,
            segments: raw.segments,
            functions: BTreeMap::new(),
        };

        let mut cs = image.disassembler()?;

        for f in raw.functions.into_iter() {
            let v = Loader::lift_function(&image, f, &mut cs)?;
            image.functions.insert(v.start_addr, v);
        }

        Ok(image)
    }
}
