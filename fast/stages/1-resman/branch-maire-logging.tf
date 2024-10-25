module "branch-maire-logging-folder" {
  source = "../../../modules/folder"
  parent = module.branch-maire-shared-folder.id
  name   = "maire-logging-fldr"

}