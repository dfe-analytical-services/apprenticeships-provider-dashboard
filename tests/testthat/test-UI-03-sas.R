# Start an app running ========================================================
app <- AppDriver$new(
  name = "UI-03-sas",
  load_timeout = 45 * 1000,
  timeout = 20 * 1000,
  expect_values_screenshot_args = FALSE
)

# Setting useful SaS inputs and outputs
sas_inputs <- c("subjects_and_standards", "sas-measure", "sas-provider", "sas-year")
sas_outputs <- c("sas-sas_provider_table_title", "sas-sas_subject_area_table", "sas-sas_provider_table")

# Test Subjects and standards tab loads
app$set_inputs(`learner_characteristics-provider` = "Total")
app$set_inputs(`nps-provider` = "All providers")
app$click("subjects_and_standards")
app$expect_values(input = sas_inputs, output = sas_outputs)

# Check a single provider can be selected
app$set_inputs(`sas-provider` = "Nottingham College")
app$expect_values(input = sas_inputs, output = sas_outputs)

# Check multiple providers can be selected
app$set_inputs(`sas-provider` = c(
  "Nottingham College", "Tyne Coast College", "Coventry College",
  "The Fernandes And Rosario Consulting Limited"
))
app$expect_values(input = sas_inputs, output = sas_outputs)

# Check the measure change to Enrolments changes the outputs
app$set_inputs(`sas-measure` = "Enrolments")
app$expect_values(input = sas_inputs, output = sas_outputs)

# Check the measure change to Achievements changes the outputs
app$set_inputs(`sas-measure` = "Achievements")
app$expect_values(input = sas_inputs, output = sas_outputs)

# Check the year change to 2022/23 changes the outputs
app$set_inputs(`sas-year` = "2022/23")
app$expect_values(input = sas_inputs, output = sas_outputs)
