#include <cstddef>
#include <filesystem>
#include <fstream>
#include <map>
#include <set>
#include <string>
#include <utility>
#include <vector>

#include "inputs/generated_inputs_manager.hpp"
#include "helpers/filesystem.hpp"
#include "helpers/ordered_relation.hpp"
#include "helpers/string.hpp"
#include "input_generation_sessions/afl_run/afl_run_utils.hpp"
#include "kernel/cbd_instance.hpp"
#include "kernel/constants.hpp"

namespace inputs
{

std::map<helpers::OrderedRelation<int>, std::string> GeneratedInputsManager::adversarialSequencesPrecedencesToWildcardFilename;
std::map<helpers::OrderedRelation<int>, std::string> GeneratedInputsManager::wildcardedAdversarialSequencesPrecedencesToWildcardFilename;
std::map<helpers::OrderedRelation<int>, std::string> GeneratedInputsManager::staticAdversarialSequencesPrecedencesToWildcardFilename;
bool GeneratedInputsManager::loadedAdversarialSequencesPrecedencesToWildcardFilename = false;

void GeneratedInputsManager::buildAdversarialSequencesPrecedencesToWildcardFilename()
{
    std::string generatedAdversarialSequencesByCSLProcessPath = kernel::CBDInstance::getInstance().getCSLProcessStuffPath() + CSLPROCESS_V2_ADVERSARIAL_SEQUENCES_DIR_NAME;
    std::string currentAdversarialSequenceFilename;
    std::string adversarialSequenceContentFieldKey = input_generation_sessions::afl_run::utils::getAWildcardFilenameParameterKey(input_generation_sessions::afl_run::utils::WildcardFilenameParameter::CONTENT);
    helpers::OrderedRelation<int> currentAdversarialSequencePrecedence;

    for (const std::filesystem::directory_entry& adversarialSequenceFile : std::filesystem::directory_iterator(generatedAdversarialSequencesByCSLProcessPath))
    {
        currentAdversarialSequenceFilename = adversarialSequenceFile.path().filename().string();
        currentAdversarialSequencePrecedence = helpers::OrderedRelation<int>(input_generation_sessions::afl_run::utils::getParametersFromWildcardFilename(currentAdversarialSequenceFilename).at(adversarialSequenceContentFieldKey));

        adversarialSequencesPrecedencesToWildcardFilename.insert(std::pair<helpers::OrderedRelation<int>, std::string>(currentAdversarialSequencePrecedence, currentAdversarialSequenceFilename));
    }
}

void GeneratedInputsManager::buildWildcardedAndStaticAdversarialSequencesPrecedencesToWildcardFilename()
{
    std::string currentAdversarialSequencePath;
    std::string currentAdversarialSequenceContent;
    int numberOfStarsInAdversarialSequenceContent;

    for (const std::pair<const helpers::OrderedRelation<int>, std::string>& precedenceToAdversarialSequenceFilename : adversarialSequencesPrecedencesToWildcardFilename)
    {
        currentAdversarialSequencePath = kernel::CBDInstance::getInstance().getCSLProcessStuffPath() + CSLPROCESS_V2_ADVERSARIAL_SEQUENCES_DIR_NAME "/" + precedenceToAdversarialSequenceFilename.second;
        currentAdversarialSequenceContent = helpers::filesystem::getFileContent(currentAdversarialSequencePath);

        numberOfStarsInAdversarialSequenceContent = helpers::string::countOccurrencesOfCharacter(currentAdversarialSequenceContent, '*');

        if (numberOfStarsInAdversarialSequenceContent > 0)
        {
            wildcardedAdversarialSequencesPrecedencesToWildcardFilename.insert(precedenceToAdversarialSequenceFilename);
        }
        else if (numberOfStarsInAdversarialSequenceContent == 0)
        {
            staticAdversarialSequencesPrecedencesToWildcardFilename.insert(precedenceToAdversarialSequenceFilename);
        }
    }
}

inline void GeneratedInputsManager::staticInitialization()
{
    if (loadedAdversarialSequencesPrecedencesToWildcardFilename == false)
    {
        buildAdversarialSequencesPrecedencesToWildcardFilename();
        buildWildcardedAndStaticAdversarialSequencesPrecedencesToWildcardFilename();

        loadedAdversarialSequencesPrecedencesToWildcardFilename = true;
    }
}

void GeneratedInputsManager::buildInputIdWithInputFilename()
{
    std::string currentInputFilename;
    int currentInputId;
    input_generation_sessions::afl_run::utils::AFLQueueFilenameParameter idParameter = input_generation_sessions::afl_run::utils::AFLQueueFilenameParameter::ID;
    std::string idParameterAsString = input_generation_sessions::afl_run::utils::getAFLQueueFilenameParameterKey(idParameter);
    int i = 0x10000;

    for (const std::filesystem::directory_entry& inputFile : std::filesystem::directory_iterator(this->inputsPath))
    {
        currentInputFilename = inputFile.path().filename().string();
        currentInputId = std::stoi(input_generation_sessions::afl_run::utils::getParametersFromAFLQueueFilename(inputFile.path().filename().string()).at(idParameterAsString)) + i;

        this->inputIdWithInputFilename.insert(std::pair<int, std::string>(currentInputId, currentInputFilename));

        i += 0x10000;
    }
}

GeneratedInputsManager::GeneratedInputsManager() :
    currentDepth(0),
    tag(std::nullopt)
{
    staticInitialization();
}

GeneratedInputsManager::GeneratedInputsManager(std::string _tag) :
    currentDepth(0),
    tag(_tag)
{
}

GeneratedInputsManager::GeneratedInputsManager(std::string _inputsPath, int _currentDepth) :
    inputsPath(_inputsPath),
    currentDepth(_currentDepth),
    tag(std::nullopt)
{
    staticInitialization();

    this->buildInputIdWithInputFilename();
}

GeneratedInputsManager::GeneratedInputsManager(std::string _tag, std::string _inputsPath, int _currentDepth) :
    inputsPath(_inputsPath),
    currentDepth(_currentDepth),
    tag(_tag)
{
    staticInitialization();

    this->buildInputIdWithInputFilename();
}

void GeneratedInputsManager::generateWildcardFilesForThisDepth()
{
    std::string outputWildcardsDirectory = OUTPUT_DIR_GENERATED_WILDCARDS "/" + std::to_string(this->currentDepth); // TODO : Peut-être à mieux généraliser...
    std::string currentAdversarialSequenceFilename;
    std::string currentAdversarialSequenceContent;
    std::string newWildcardContent;
    std::ofstream newWildcardFileOfstream;
    int i = 0;

    std::filesystem::create_directory(outputWildcardsDirectory);

    for (const std::pair<const helpers::OrderedRelation<int>&, const std::set<std::string>&> concretizedPrecedence : this->concretizedPrecedences)
    {
        for (const std::string& concretizedPrecedenceValue : concretizedPrecedence.second)
        {
            for (std::pair<const helpers::OrderedRelation<int>&, const std::string&> candidateWildcard : this->adversarialSequencesPrecedencesToWildcardFilename)
            {
                if (concretizedPrecedence.first << candidateWildcard.first)
                {
                    currentAdversarialSequenceFilename = candidateWildcard.second;
                    currentAdversarialSequenceContent = helpers::filesystem::getFileContent(kernel::CBDInstance::getInstance().getCSLProcessStuffPath() + CSLPROCESS_V2_ADVERSARIAL_SEQUENCES_DIR_NAME "/" + currentAdversarialSequenceFilename);

                    if (helpers::string::countOccurrencesOfCharacter(currentAdversarialSequenceContent, '*') > 0)
                    {
                        newWildcardContent = helpers::string::merge(concretizedPrecedenceValue, currentAdversarialSequenceContent, this->currentDepth, '\n');

                        if (this->tag.has_value() == false)
                        {
                            newWildcardFileOfstream = std::ofstream(outputWildcardsDirectory + "/" + currentAdversarialSequenceFilename + ";merged" + std::to_string(this->currentDepth) + "id=" + std::to_string(i));
                        }
                        else
                        {
                            newWildcardFileOfstream = std::ofstream(outputWildcardsDirectory + "/" + currentAdversarialSequenceFilename + ";merged" + std::to_string(this->currentDepth) + "id=" + std::to_string(i) + ";tag=" + this->tag.value());
                        }

                        newWildcardFileOfstream << newWildcardContent;

                        newWildcardFileOfstream.close();
                    }

                    ++i;
                }
            }
        }
    }
}

std::vector<std::string> GeneratedInputsManager::getAllWildcardedAdversarialSequencesFilenames()
{
    std::vector<std::string> result;

    for (const std::pair<const helpers::OrderedRelation<int>, std::string>& currentPair : wildcardedAdversarialSequencesPrecedencesToWildcardFilename)
    {
        result.push_back(currentPair.second);
    }

    return result;
}

std::vector<std::string> GeneratedInputsManager::getAllStaticAdversarialSequencesFilenames()
{
    std::vector<std::string> result;

    for (const std::pair<const helpers::OrderedRelation<int>, std::string>& currentPair : staticAdversarialSequencesPrecedencesToWildcardFilename)
    {
        result.push_back(currentPair.second);
    }

    return result;
}

std::vector<std::vector<std::string>> GeneratedInputsManager::dispatchWildcardsFilenamesOnNCPUs(std::size_t cpus)
{
    std::vector<std::vector<std::string>> result;
    std::vector<std::string> adversarialSequences = this->getAllWildcardedAdversarialSequencesFilenames();
    std::size_t i;
    std::size_t j = 0;
    std::vector<std::string> currentVector;
    helpers::OrderedRelation<int> currentId;

    for (i = 0; i < cpus; ++i)
    {
        result.push_back(std::vector<std::string>());

        for (j = 0; j < (adversarialSequences.size() / cpus); ++j)
        {
            result.at(i).push_back(adversarialSequences.at(j));
        }
    }

    return result;
}

} // namespace inputs