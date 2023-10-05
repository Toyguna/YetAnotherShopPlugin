# [TF2] YetAnotherShopPlugin

## UNDER CONSTRUCTION - NOT USABLE YET

## What is YASP?
YetAnotherShopPlugin is a lightweight store/shop plugin for TF2 (only TF2 for now). YASP's purpose is to be easy to set up and highly customizable; to be the selection for servers with a lesser focus on a store plugin.

## How do I install?
Paste the `addons` folder into your `<server_directory>/tf` directory.

## How do I set up a MySQL Database?
  1. Create a database configuration with information of your database.
  2. Go to directory `tf/cfg/sourcemod/plugin.YetAnotherShopPlugin.cfg` ( Load the plugin first if the file does not exist )
  3. Change ConVar `yasp_database_configuration` to your configuration.
  4. Run your TF2 server.

## How do I add custom items to the inventory?
Inside your `addons/sourcemod/configs` folder you should see a folder named "YetAnotherShopPlugin"
  - `shop.cfg` to create items.
  - `type/nametag.cfg`, `type/trail.cfg` etc. to edit items' type properties.

### Structure of `shop.cfg`:
```
"ShopItems"
{
    "nt_example" // Class of item, for means of clean code, you can prefix the items with it's type
    {
        "display" "Example" // Display name of item

        "price" "5" // Price of item
        "buyable" "1" // Is item buyable? (0: false, 1: true)
        "refundable" "1" // Is item refundable? (-1: false; 0-1: percentage of refund given)

        "type" "nametag" // Type of the item
    }
}
```

### Structure of type config files:
nametag.cfg:
```
"Nametags"
{
    "nt_example" // Class of item with corresponding type
    {
        "nametag" "{orange}Example" // Nametag, supports "morecolors"
    }
}
```
