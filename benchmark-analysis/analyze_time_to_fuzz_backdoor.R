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

cbd_generate_time_to_find_backdoor_result <- system("./cbd/generate_time_to_find_backdoors_csv.sh", intern = TRUE)
cbd_ablated_time_to_find_backdoor_result <- system("./cbd_ablated/generate_time_to_find_backdoors_csv.sh", intern = TRUE)
cbd_ablated_default_seed_time_to_find_backdoor_result <- system("./cbd_ablated_default_seed/generate_time_to_find_backdoors_csv.sh", intern = TRUE)
cbd_ablated_without_multilayer_fuzzing_time_to_find_backdoor_result <- system("./cbd_ablated_without_multilayer_fuzzing/generate_time_to_find_backdoors_csv.sh", intern = TRUE)
rosa_generate_time_to_find_backdoor_result <- system("./rosa/generate_time_to_find_backdoors_csv.sh", intern = TRUE)

print(cbd_generate_time_to_find_backdoor_result)
print(cbd_ablated_time_to_find_backdoor_result)
print(cbd_ablated_default_seed_time_to_find_backdoor_result)
print(cbd_ablated_without_multilayer_fuzzing_time_to_find_backdoor_result)
print(rosa_generate_time_to_find_backdoor_result)

data_cbd <- read.csv(text = cbd_generate_time_to_find_backdoor_result, header = TRUE, sep = ',')
data_cbd_ablated <- read.csv(text = cbd_ablated_time_to_find_backdoor_result, header = TRUE, sep = ",")
data_cbd_ablated_default_seed <- read.csv(text = cbd_ablated_default_seed_time_to_find_backdoor_result, header = TRUE, sep = ",")
data_cbd_ablated_without_multilayer_fuzzing <- read.csv(text = cbd_ablated_without_multilayer_fuzzing_time_to_find_backdoor_result, header = TRUE, sep = ",")
data_rosa <- read.csv(text = rosa_generate_time_to_find_backdoor_result, header = TRUE, sep = ',')

u_test_time_to_find_backdoor_cbd <- vector_filled_with_values(data_cbd$time_to_find_the_backdoor, timeout, number_of_runs)
u_test_time_to_find_backdoor_cbd_ablated <- vector_filled_with_values(data_cbd_ablated$time_to_find_the_backdoor, timeout, number_of_runs)
u_test_time_to_find_backdoor_cbd_ablated_default_seed <- vector_filled_with_values(data_cbd_ablated_default_seed$time_to_find_the_backdoor, timeout, number_of_runs)
u_test_time_to_find_backdoor_cbd_ablated_without_multilayer_fuzzing <- vector_filled_with_values(data_cbd_ablated_without_multilayer_fuzzing$time_to_find_the_backdoor, timeout, number_of_runs)
u_test_time_to_find_backdoor_rosa <- vector_filled_with_values(data_rosa$time_to_find_the_backdoor, timeout, number_of_runs)

print(u_test_time_to_find_backdoor_cbd)
print(u_test_time_to_find_backdoor_cbd_ablated)
print(u_test_time_to_find_backdoor_cbd_ablated_default_seed)
print(u_test_time_to_find_backdoor_cbd_ablated_without_multilayer_fuzzing)
print(u_test_time_to_find_backdoor_rosa)

u_test_cbd_rosa <- wilcox.test(
    u_test_time_to_find_backdoor_cbd,
    u_test_time_to_find_backdoor_rosa
)

u_test_cbd_cbd_ablated <- wilcox.test(
    u_test_time_to_find_backdoor_cbd,
    u_test_time_to_find_backdoor_cbd_ablated
)

u_test_cbd_cbd_ablated_default_seed <- wilcox.test(
    u_test_time_to_find_backdoor_cbd,
    u_test_time_to_find_backdoor_cbd_ablated_default_seed
)

u_test_cbd_cbd_ablated_without_multilayer_fuzzing <- wilcox.test(
    u_test_time_to_find_backdoor_cbd,
    u_test_time_to_find_backdoor_cbd_ablated_without_multilayer_fuzzing
)

times <- seq(from = 5, to = 3600, by = 10)

number_of_times_the_backdoor_was_found <- data.frame("times" = times)
number_of_times_the_backdoor_was_found[, "cbd"] <- replicate(length(times), 0)

i <- 1

for (current_time in times)
{
    for (detection_time in data_cbd$time_to_find_the_backdoor)
    {
        if (detection_time <= current_time)
        {
            number_of_times_the_backdoor_was_found$cbd[i] <- number_of_times_the_backdoor_was_found$cbd[i] + 1
        }
    }

    i <- i + 1
}

number_of_times_the_backdoor_was_found$cbd_probability_of_detection = number_of_times_the_backdoor_was_found$cbd / number_of_runs
number_of_times_the_backdoor_was_found$cbd_probability_of_survival = 1 - number_of_times_the_backdoor_was_found$cbd_probability_of_detection

number_of_times_the_backdoor_was_found[, "rosa"] <- replicate(length(times), 0)

i <- 1

for (current_time in times)
{
    for (detection_time in data_rosa$time_to_find_the_backdoor)
    {
        if (detection_time <= current_time)
        {
            number_of_times_the_backdoor_was_found$rosa[i] <- number_of_times_the_backdoor_was_found$rosa[i] + 1
        }
    }

    i <- i + 1
}

print(number_of_times_the_backdoor_was_found)

number_of_times_the_backdoor_was_found$rosa_probability_of_detection = number_of_times_the_backdoor_was_found$rosa / number_of_runs
number_of_times_the_backdoor_was_found$rosa_probability_of_survival = 1 - number_of_times_the_backdoor_was_found$rosa_probability_of_detection

pdf("./probability_of_survival_over_time.pdf")

plot(number_of_times_the_backdoor_was_found$times,
    number_of_times_the_backdoor_was_found$cbd_probability_of_survival,
    ylim = c(
        0,
        1
    ),
    type = 'o',
    xlab = "Timeout in s",
    ylab = "Survival probability",
    col = "blue",
    pch = "o",
    lty = 1
)

points(number_of_times_the_backdoor_was_found$times,
    number_of_times_the_backdoor_was_found$rosa_probability_of_survival,
    col = "red",
    pch = "o"
)

lines(number_of_times_the_backdoor_was_found$times,
    number_of_times_the_backdoor_was_found$rosa_probability_of_survival,
    col = "red"
)

model_log_cbd <- lm(
    number_of_times_the_backdoor_was_found$cbd_probability_of_survival ~ log(number_of_times_the_backdoor_was_found$times)
)

model_log_rosa <- lm(
    number_of_times_the_backdoor_was_found$rosa_probability_of_survival ~ log(number_of_times_the_backdoor_was_found$times)
)

regression_log_cbd = predict(
    model_log_cbd,
    newdata = list(
        x = seq(
            from = 0,
            to = 13,
            length.out = 1
        )
    ),
    interval="confidence"
)

regression_log_rosa = predict(
    model_log_rosa,
    newdata = list(
        x = seq(
            from = 0,
            to = 13,
            length.out = 1
        )
    ),
    interval="confidence"
)

matlines(
    number_of_times_the_backdoor_was_found$times,
    regression_log_cbd,
    lwd = 2
)

matlines(
    number_of_times_the_backdoor_was_found$times,
    regression_log_rosa,
    lwd = 2
)

legend("topright",
    legend = c(
        "CBD",
        "ROSA"
    ),
    col = c(
        "blue",
        "red"
    ),
    pch = c(
        "o",
        "o"
    ),
    lty = c(
        1,
        1
    )
)

dev.off()

print(u_test_cbd_rosa)
print(u_test_cbd_cbd_ablated)
print(u_test_cbd_cbd_ablated_default_seed)
print(u_test_cbd_cbd_ablated_without_multilayer_fuzzing)