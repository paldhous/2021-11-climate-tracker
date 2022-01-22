# configuration
should_upload <- as.integer(Sys.getenv("SHOULD_UPLOAD", 0))
project_dir <- Sys.getenv("CLIMATE_TRACKER_DIR", getwd())
setwd(project_dir)

# load required packages
library(aws.s3)

# get current UNIX time in UTC
timestamp <- as.numeric(Sys.time())

# write JS for upate div
update_string <- paste0("(() => {
  document.write(\"<div id='bfn-last-updated' style='font-size: 0.75em; font-style: italic;'></div>\");
  let el = document.getElementById(\"bfn-last-updated\");
  let date = new Date(", timestamp, " * 1000);
  let options = {
    weekday: 'short', year: 'numeric', month: 'short', day: 'numeric',
    hour: 'numeric', minute: '2-digit', timeZoneName: 'long', hour12: true 
    };
  el.innerHTML = \"Data last updated: \" + date.toLocaleString(\"en-US\", options) + \".\";
  }).call(this);")

# write to file and push to data.buzzfeed.com
write(update_string, file = "js/metadata.js", append = FALSE)
if (should_upload == 1) {
  put_object(file = "js/metadata.js", object = "metadata.js", bucket = "data.buzzfeed.com/projects/climate-files")
}

