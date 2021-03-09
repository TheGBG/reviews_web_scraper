# This program scraps reviews from any amazon product that the user desires
# I'll be using the book The Shining (Stephen King) as an example, but you can
# scrap pretty much any procut from amazon using this program and changing
# the link

# If you want to scrape reviews from a different site, you'll have to change
# more stuff in the script, such as the css locators, but this code could be 
# a template

# Packages
library(rvest)
library(dplyr)
library(stringr)

# Link to the desired product to analyse.
link <- "https://www.amazon.co.uk/product-reviews/1444720724/ref=cm_cr_othr_d_show_all_btm?ie=UTF8&reviewerType=all_reviews"
page <- read_html(link) # get the source html of the page

# Easy example: get the title of the product
product_title <- page %>% 
  html_node(".a-text-ellipsis .a-link-normal") %>% # CSS locator of the 
                                                   # desired object, easy to 
                                                   # get with Selector Gadget
  html_text()

product_title # The Shining

# Now with the reviews. Careful, they're on different pages.
# We need to figure out how the web cahges when we click on "next page"

# In this case is clear. The link mantains its original form, but at the end, 
# there is "pageNumer=n" changing each time we change the page

# This is only the first page, as we're still using the old link
first_page <- page %>% 
  html_nodes(".review-text-content span") %>% 
  html_text()

# We'll use a for loop to loop over every page and scrap what we need

# 1. Change the original link to include page number = 1, and get the html again
link <- "https://www.amazon.co.uk/product-reviews/1444720724/ref=cm_cr_getr_d_paging_btm_next_3?ie=UTF8&reviewerType=all_reviews&pageNumber=1"
page <- read_html(link)

# 2. Write the for loop
# Tricky part: we need to know how many reviews there are in total, and how many 
# reviews per page, so we can get the number of pages to loop over.

# If we plan to scrap the same web recurrently and we want to automate the 
# count of pages, we can look for the data scraping
total_reviews <- page %>% 
  html_node("#filter-info-section span") %>% # locator of the total n of
                                             # reviews in your site
  html_text() %>% 
  
  # Regex to get only what we need and convert it to numeric
  str_remove_all("\n") %>%
  str_replace_all(",", "") %>% 
  str_match_all("[:digit:]+ global reviews") %>% # in this case, the number of
                                                 # interest it's located 
                                                 # nex to "global reviews"
  str_match_all("[:digit:]+") %>% 
  as.numeric()

# This process will be different for each website, but the idea is to 
# automate the step that calculates the total number of pages, so that the 
# program still works when more reviews are added to the product.

# Now we need to divide the n of total reviews by the n of reviews
# per page. We need to round the number upwards, so just do floor + 1

n_of_pages <- floor(total_reviews / length(first_page)) + 1

# Now the loop
# Initialize the vector where youre going to write the reviews
reviews <- c()

# Loop over the toal number of pages. This is the part where the scrap is done
for (i in 1:n_of_pages) {
  
  # Make sure that the link changes with every iteraton: paste0 of the 
  # static part and the number of page
  link <- paste0("https://www.amazon.co.uk/product-reviews/1444720724/ref=cm_cr_getr_d_paging_btm_next_303?ie=UTF8&reviewerType=all_reviews&pageNumber=",
                i)
  
  # Now the process is the same
  page <- read_html(link) # get the html
  
  review_page_n <- page %>% 
    html_nodes(".review-text-content span") %>% # scrap the reviews
    html_text()
  
  reviews <- c(reviews, review_page_n) # this updates the data with 
                                       # each page scraped
  
  print(paste0("Page ", i, " successfully scraped")) # keep track of process

  }

# Get the reviews into a dataframe
df_reviews <- data.frame(reviews)
View(df_reviews)

# Save it to csv wherever you want
write.csv(df_reviews, 
          "data/scraped_reviews.csv",
          row.names = FALSE,
          fileEncoding = "UTF-8")

# There you go! You have your brand new scraped text on a dataset, and you
# can use it to whatever you want.