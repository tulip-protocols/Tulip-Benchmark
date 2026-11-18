use analysis::AnalysableBlock;
use std::fmt::Debug;

pub trait Block: AnalysableBlock + Debug {
    fn start_addr(&self) -> u64;
    fn end_addr(&self) -> u64;
    fn dests(&self) -> &[u64];
    fn into_boxed(self) -> Box<Block>;
}
