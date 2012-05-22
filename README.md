spree_rkbb_import_scripts
=========================

The scripts I use to import and update lots of products to my spree store

This script is based on an original gist shared by BDQ (https://github.com/bdq) for an earlier version of Spree.

This is working for me for Spree 1.0 and greater

Step 1
======
Get your data.
I use a script 'getdata.sh' to get it from my internal database server. It's included so you can use it as a starting point.
It outputs data to 'webdata-utf8.csv'.
Column titles are not important. There are only 3.
* Product Code (also known as SKU), 
* Title (our selling descriptions are actually Spree Titles)
* Price (in our case, before tax - you'll see tax added in a later script)

Step 2
======
Have products pushed into their Taxons
taxonsetter.csv is a file that uses regular expressions to decide if and where to put a product in a taxon. I've included an example.
Key things:
* Regex colum = regular expression 
* Target = Which database field you're trying to match with the Regex
* Taxon = Which taxon matching products will be pushed into
* Shipping = Matching products are assigned to this shipping category (optional)
* Notes = Somewhere I write notes about what I'm doing with this regex

Step 3
======
Update the import rake task to suit your needs
it lives in my spree store folder at lib/tasks/import_rkbb.rake
Note you'll need to have: gem 'colorize' in your Gemfile - the pretty colours help the teminal output become more readable
Things to check before you use:
* I need to have VAT inclusive prices, but my export is VAT Exclusive
  so I Add the VAT in this script as it's always 20% for my products
* I have a tax category of VAT that's set for every product. You'll need to
  rename to match your tax category.
Part 1: You can export data from Spree. Useful to see what you can impiort to and play with.  run with: export_rkbbproducts
Part 2: The import routine.
Start the import with: rake spree:import_rkbb_products file=webdata-utf8.csv
If you want to target your production server, use:
rake spree:import_rkbb_products file=webdata-utf8.csv RAILS_ENV=production

Things to be aware of
=====================
If a product is deleted in Spree, the deleted at date is set and the product remains. I can't remember if the product price will still be updated. You will see at the end of the task a summary which will show you how many warnings there were (you will get a warning if a product you are updating is marked deleted in spree, but the update will continue).

This isn't very quick. About 1 product per second. However, I run it from a local server updating our web server - so I don't care if it takes hours and hours to run!  As it's running on my local server, it only uses the database on the web server (so no noticable performance hit for us and I imagine that applies too for Heroku platform users - you can run your data updates from your local machines without needing extra workers). I've left it running to add/update a dataset of 134,000 product entries.

You are free to take, change, modify the script to your needs.
If you spot an error or a more efficient way of coding the updates then pull requests are welcome (or a github message, or a post in the spree forum) and I'll fix it for any future users.

Thanks,
Steve
