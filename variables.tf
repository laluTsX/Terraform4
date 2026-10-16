variable "subscription_id" {
    type    = string
    default = "9b3780b7-1359-4abf-8c1a-425dc7856178"
}

variable "location" {
    type    = string
    default = "mexicocentral"
}

variable "prefix" {
    type    = string
    default = "lz"
}

variable "vm_size" {
    type    = string
    default = "Standard_B2ats_v2"
}

variable "db_sku" {
    type    = string
    default = "B_Standard_B1ms"
}

variable "tags" {
    type = map(string)
    default = {
        entorno = "prod"
        proyecto = "landing-zone"
    }
}