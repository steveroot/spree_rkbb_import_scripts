#Needs gem colorize!

require 'colorize'
require 'csv'
namespace:spree do
    desc "Export Products to CSV File"
    task :export_rkbb_products => :environment do

      products = Spree::Product.find(:all)
      puts "Exporting to #{Rails.root}/products.csv"
      CSV.open("#{Rails.root}/products.csv", "w") do |csv|

        csv << ["id", "sku", "name", "description","available_on", 
                "deleted_at", "created_at", "updated_at",
                "shipping_category_id","tax_category_id", "price" ]

        products.each do |p|
          csv << [
                  p.id,
                  p.sku,
                  p.name,
                  p.description,
                  p.available_on,
                  p.deleted_at,
                  p.created_at,
                  p.updated_at,
                  p.shipping_category_id,
                  p.tax_category_id,
                  p.price
                  ]

        end
      end
      puts "Export Complete".green
    end  
  
  
  
  desc "Update / Import RKBB products from CSV File, expects file=/path/to/import.csv"
  task :import_rkbb_products => :environment do
#Steve's reminder:
#Run this: rake spree:import_rkbb_products file=myfile.csv
 
   #Processing speed report
   tstart = Time.new
   
   #set counters for new and updated info at end  
    n = 0 #new
    u = 0 #updated
    w = 0 #warnings

    #Get object for standard Tax    
    tax = Spree::TaxCategory.find_by_name("VAT") 
    #Tax Rate has to be on product import. Our internal
    #database holds prices Ex VAT. As we only have one
    #VAT rate to worry about, we can simply add VAT 
    #when products are imported to spree as a 
    #multiplier (ie add 20% is multiply by 1.2)
    currenttax = 1.2   


    CSV.foreach(ENV['file']) do |row|
    
   next if row[0].downcase == "shortcode"  #skip header row
   
   #SKU == RKBB Shortcode.  SKU is held in Variants table   
   if Spree::Variant.find_by_sku(row[0].to_s)
     puts "found and updating #{row[0]}".green
    
    variant = Spree::Variant.find_by_sku(row[0].to_s)
    product = Spree::Product.find(variant.product_id)
    
    #product.sku = row[0].to_s.force_encoding("UTF-8") 
        #logically, the sku can't be updated. We're only here
        #because we matched the sku!  
    product.name = row[1].to_s.force_encoding("UTF-8")
    product.price = row[2].to_d * currenttax
    #Using this rake task, the product.updated_at wasn't being updated, so I'm doing it here
    product.update_attribute(:updated_at, Time.now)
    u += 1
    #If we have 'deleted' a product on Spree, it gets a date
    #in the deleted_at column (products table) and although
    #the data will update, it still won't show.  This may be a
    #good thing, so we'll output a warning.
    #If we want to show the product, maybe there's a spree 
    #undelete option (or just remove the deleted_at  date from the 
    #database perhaps
   
    unless product.deleted_at.nil?
     w += 1
     puts "Warning: #{row[0]} is deleted in spree and won't show (XXXtodoXXX check data was updated)".red
    end

##############
#  Do I need to ensure SKU is unique?
#  .. if I'm only adding through code, it will be
#  .. but it would be possible to manually add same SKU
#
# if spree has an SKU not in shortcodes, do I mark as deleted
#############
    else
     puts "#{row[0]} is a new product".cyan
     product = Spree::Product.new()
     n += 1
     product.available_on = Time.new
     
    end

    
      product.sku = row[0].to_s.force_encoding("UTF-8") 
      product.name = row[1].to_s.force_encoding("UTF-8")
     # product.description = row[3]
      product.price = row[2].to_d * currenttax
      #set defaults for products, like VAT
      product.tax_category_id = tax.id
#############
#need to add shipping selection somehow. Maybe do that
#when pushing products into taxons, as the taxon 
#is probably a good definition of shipping type
#this next line was for my debug processing this rake task.
#puts tax.inspect
########
      product.save!
    
#Adding to taxons
#Need to set the logic somewhere to check if this product needs to go into a taxon.    
#example: 
#WHERE shortcode like "CR MI %", find-taxon-by-name 'Milano'
#WHERE description like "%Neff%", find-taxon-by-name 'Appliances'
#I have a spreadsheet in csv format, with columns of:
#Regex, Target, Taxon, Notes
#where Regex is the regular expression to see if the current product matches
#Target is the column to apply the regex too, eg 'product.sku' or 'product.name'
#to target the SKU or the products description
#Taxon is the taxon we're dropping the product into
#Notes - are for me to know what and why I'm doing this match

  CSV.foreach('taxonsetter.csv') do |row|
     next if row[0].downcase == "regex"  #skip header row
     #Regex = row[0]
     #target = row[1]
     #Taxon = row[2]
     #Shipping Category = row[3]
     #notes = row[4]


     #Where the target is 'product.sku'
     #puts "#{row[1]}"
     if row[1] == "product.sku"
       #puts ">>>>>>>SKU Match #{row[0]}"
       if(/#{row[0]}/.match(product.sku))
         taxon = Spree::Taxon.find_by_name("#{row[2]}")
          if product.taxons.find_by_id(taxon)
           puts ">> Taxon was already set #{taxon.name}"
           else
           product.taxons << taxon  #associates product with taxon
           puts ">> Taxon added #{taxon.name}"
          end
          
          ####Shipping#####
          if row[3] == nil
           #No shipping category set, this would be the default, set
           # nil in case this is a new setting
           product.shipping_category = nil
           puts ">> shipping set to default"
          else 
           #Read the shipping category
           ship = Spree::ShippingCategory.find_by_name("#{row[3]}")
           product.shipping_category_id = ship.id 
           puts ">> shipping set to " + ship.name
	        end 
          ######Shipping End#####          
          product.save!   
       end
     
     #Where the target is 'product.name'
     else row[1] == "product.name"
       #puts ">>>>>>Name Match #{row[0]}"
       if(/#{row[0]}/.match(product.name))
         taxon = Spree::Taxon.find_by_name("#{row[2]}")
          if product.taxons.find_by_id(taxon)
           puts ">> Taxon was already set #{taxon.name}"
           else
           product.taxons << taxon  #associates product with taxon
           puts ">> Taxon added #{taxon.name}"
          end
         ####Shipping#####
         if row[3] == nil
           #No shipping category set, this would be the default, set
           # nil in case this is a new setting
           product.shipping_category = nil
           puts ">> shipping set to default"
           else 
           #Read the shipping category
           ship = Spree::ShippingCategory.find_by_name("#{row[3]}")
           product.shipping_category_id = ship.id 
           puts ">> shipping set to " + ship.name
         end 
         ######Shipping End#####    
       end
     end

    #end of taxon setting
    end
  end
  
    puts ""
    puts "Import Completed ".green + "Added: #{n}".cyan + " Updated: #{u}".green + " Warnings: #{w}".red
   
   
  #Processing Speed Report
  tend = Time.new 
  tdiff = (tend - tstart).round  
  prodpersec = ((n + u)/tdiff).round
  puts "Duration: ".green + "#{tdiff} seconds,".yellow + " a rate of ".green + "#{prodpersec} products per second".yellow
  puts ""
  end
end
