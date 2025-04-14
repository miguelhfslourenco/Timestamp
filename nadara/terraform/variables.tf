variable "common_tags" {
  type = map(string)
  default = {
    Context 	= "All Nadara group"
    Owner   	= "IT Department"
    Application = "Dataplatform"
  }
}

