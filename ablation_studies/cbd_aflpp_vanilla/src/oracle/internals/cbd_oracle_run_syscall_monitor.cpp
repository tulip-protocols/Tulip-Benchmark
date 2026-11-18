#include <cstdlib>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "oracle/internals/cbd_oracle_run_syscall_monitor.hpp"
#include "helpers/runnables/external_binary_execution.hpp"
#include "kernel/constants.hpp"
#include "oracle/cbd_oracle.hpp"

namespace oracle::internals
{

void CBDOracleRunSyscallMonitor::jobTask() const
{
    helpers::runnables::ExternalBinaryExecution* currentSyscallMonitorRun;
    std::vector<std::string> currentSyscallMonitorRunArgs(3);
    std::string outputDirReducedSyscallsForThisStage = OUTPUT_DIR_SYSCALLS "/" + this->relatedOracle.getTag();
    std::string outputDirSyscallMonitorForThisStage = OUTPUT_DIR_SYSCALL_MONITOR "/" + this->relatedOracle.getTag();
    std::size_t currentTestingSessionIDAsStringPosition;
    std::string currentTestingSessionIDAsString;
    char* cbdPreloadEnv;
    std::map<std::string, std::string> environment;

    currentTestingSessionIDAsStringPosition = this->testingSessionResultDir.find_last_of('/');
    currentTestingSessionIDAsString = this->testingSessionResultDir.substr(currentTestingSessionIDAsStringPosition + 1);

    currentSyscallMonitorRunArgs[0] = this->testingSessionResultDir;
    currentSyscallMonitorRunArgs[1] = outputDirReducedSyscallsForThisStage;
    currentSyscallMonitorRunArgs[2] = outputDirSyscallMonitorForThisStage;

    if (this->syscallsWhitelistPathOption.has_value() == true)
    {
        currentSyscallMonitorRunArgs.push_back(this->syscallsWhitelistPathOption.value());
    }

    cbdPreloadEnv = std::getenv(PRELOAD_ENV);

    if (cbdPreloadEnv != NULL)
    {
        environment.insert(std::pair<std::string, std::string>(PRELOAD_ENV, cbdPreloadEnv));
    }

    currentSyscallMonitorRun = new helpers::runnables::ExternalBinaryExecution(kernel::CBDInstance::getInstance().getCSLProcessStuffPath() + "/syscall_monitor/syscall_monitor", currentSyscallMonitorRunArgs, environment);

    currentSyscallMonitorRun->run();
    currentSyscallMonitorRun->wait();

    delete currentSyscallMonitorRun;
}

CBDOracleRunSyscallMonitor::CBDOracleRunSyscallMonitor(const CBDOracle& _relatedOracle, std::string _testingSessionResultDir) :
    relatedOracle(_relatedOracle),
    testingSessionResultDir(_testingSessionResultDir),
    syscallsWhitelistPathOption(std::nullopt)
{
}

CBDOracleRunSyscallMonitor::CBDOracleRunSyscallMonitor(const CBDOracle& _relatedOracle, std::string _testingSessionResultDir, std::string _syscallsWhitelistPath) :
    relatedOracle(_relatedOracle),
    testingSessionResultDir(_testingSessionResultDir),
    syscallsWhitelistPathOption(_syscallsWhitelistPath)
{
}

} // namespace oracle::internals