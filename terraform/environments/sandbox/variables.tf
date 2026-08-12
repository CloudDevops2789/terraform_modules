##################################################################################################
# Common Environment Variables
##################################################################################################

variable "aws_region" {
  description = "AWS Region for this environment."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.aws_region)) > 0
    error_message = "aws_region must not be empty."
  }
}
