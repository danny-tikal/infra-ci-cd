locals {

    db_config_params_defaults = {
        readonly_user_password         = ""  
        db_schema_name                 = "public" 
        create_ro_db_user               = false
        create_reader_instance          = false
    }

#  merge the above defaults 
db_config_params = merge(
    local.db_config_params_defaults,
    var.db_config_params,
  )

}