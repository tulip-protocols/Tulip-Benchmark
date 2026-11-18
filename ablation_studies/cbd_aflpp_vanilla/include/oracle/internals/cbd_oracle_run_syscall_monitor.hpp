#ifndef CBD_ORACLE_RUN_SYSCALL_MONITOR_HPP
#define CBD_ORACLE_RUN_SYSCALL_MONITOR_HPP

#include <optional>
#include <string>

#include "oracle/cbd_oracle.hpp"
#include "helpers/runnables/job.hpp"

namespace oracle::internals
{

class CBDOracleRunSyscallMonitor : public helpers::runnables::Job
{
    private:
        const CBDOracle& relatedOracle;
        std::string testingSessionResultDir;
        std::optional<std::string> syscallsWhitelistPathOption;

    protected:
        virtual void jobTask() const override;

    public:
        CBDOracleRunSyscallMonitor(const CBDOracle& _relatedOracle, std::string _testingSessionResultDir);
        CBDOracleRunSyscallMonitor(const CBDOracle& _relatedOracle, std::string _testingSessionResultDir, std::string _syscallsWhitelistPath);
};

} // namespace oracle::internals

#endif