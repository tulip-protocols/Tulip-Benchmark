#!/bin/bash

source ../../config-benchmark.sh

R --quiet --save << EOF
vector_filled_with_values <- function(vector, value, number_of_elements_in_returned_vector)
{
    vector_length <- length(vector)

    if (vector_length < number_of_elements_in_returned_vector)
    {
        for (i in vector_length:(number_of_elements_in_returned_vector - 1))
        {
            vector <- append(vector, value)
        }
    }

    return(vector)
}

number_of_runs <- as.numeric(Sys.getenv("NUMBER_OF_RUNS"))
timeout <- as.numeric(Sys.getenv("MAIN_TIMEOUT_IN_S"))

cbd_generate_time_to_find_backdoor_result <- system("./cbd_with_site_commands/generate_time_to_find_backdoors_csv.sh", intern = TRUE)
rosa_generate_time_to_find_backdoor_result <- system("./rosa_with_site_commands/generate_time_to_find_backdoors_csv.sh", intern = TRUE)

print(cbd_generate_time_to_find_backdoor_result)
print(rosa_generate_time_to_find_backdoor_result)

data_cbd <- read.csv(text = cbd_generate_time_to_find_backdoor_result, header = TRUE, sep = ',')
data_rosa <- read.csv(text = rosa_generate_time_to_find_backdoor_result, header = TRUE, sep = ',')

u_test_time_to_find_backdoor_cbd <- vector_filled_with_values(data_cbd$time_to_find_the_backdoor, timeout, number_of_runs)
u_test_time_to_find_backdoor_rosa <- vector_filled_with_values(data_rosa$time_to_find_the_backdoor, timeout, number_of_runs)

print(u_test_time_to_find_backdoor_cbd)
print(u_test_time_to_find_backdoor_rosa)

u_test_cbd_rosa <- wilcox.test(
    u_test_time_to_find_backdoor_cbd,
    u_test_time_to_find_backdoor_rosa
)
EOF