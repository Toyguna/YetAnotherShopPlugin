# Yet Another Shop Plugin

## What is YASP?
Yet Another Shop Plugin is a store/shop plugin for TF2.

## How do I install?
Paste the `addons` folder into your `<server_directory>/tf` directory.

## How do I set up an SQL Database?
  1. Create a database configuration with information of your database.
  2. Go to directory `tf/cfg/sourcemod/plugin.YetAnotherShopPlugin.cfg` ( Load the plugin if the file does not exist )
  3. Change convar `yasp_database_configuration` to your configuration.

## How do I add custom items to the inventory?
Inside your `addons/sourcemod/configs` folder you should see a folder named "YetAnotherShopPlugin"
  - `shop.cfg` to create items.
  - `nametag.cfg`, `trail.cfg` etc. to edit item's type properties.

### Structure of `shop.cfg`:
```
"ShopItems"
{
    "nt_example" // Id of item, for means of clean code, you can prefix items corresponding to the item type
    {
        "display" "Example" // Display name of item
        "price" "5" // Price of item
        "buyable" "1" // Is item buyable? (0: false, 1: true)
        "type" "nametag" // Type of the item
    }
}
```

### Structure of type config files:
nametag.cfg:
```
"Nametags"
{
    "nt_example" // Id of item with corresponding type
    {
        "nametag" "Example" // Nametag
    }
}
```
