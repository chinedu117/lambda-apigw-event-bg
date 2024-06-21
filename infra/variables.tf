variable "project_name" {
  
  type = string
  default = "dataspan"
}

variable "tags" {
    type = map 
    default = {
        CreatedBy = "Chinedu Dimonyeka"
    }
}