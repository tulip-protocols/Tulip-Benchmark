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

#cbd_false_positives <- system("echo \"run,nb_fp\" && cd cbd && ./get_number_of_false_positives.sh | tr \":\" \",\"", intern = TRUE)
cbd_false_positives <- system("echo \"run,nb_fp\" && cat ./cbd/fp | tr \":\" \",\"", intern = TRUE)
rosa_false_positives <- system("echo \"nb_fp,run\" && cd rosa && ./get_number_of_false_positives.sh | sed -re \"s/^ *//g\" | tr \" \" \",\"", intern = TRUE)

print(cbd_false_positives)
print(rosa_false_positives)

data_cbd <- read.csv(text = cbd_false_positives, header = TRUE, sep = ',')
data_rosa <- read.csv(text = rosa_false_positives, header = TRUE, sep = ',')

u_test_false_positives_cbd <- vector_filled_with_values(data_cbd$nb_fp, 0, number_of_runs)
u_test_false_positives_rosa <- vector_filled_with_values(data_rosa$nb_fp, 0, number_of_runs)

print(u_test_false_positives_cbd)
print(u_test_false_positives_rosa)

u_test_cbd_rosa <- wilcox.test(
    u_test_false_positives_cbd,
    u_test_false_positives_rosa
)

print(u_test_cbd_rosa)