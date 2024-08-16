locals {
    rules_csv = csvdecode(file(var.rules_file))
 
}