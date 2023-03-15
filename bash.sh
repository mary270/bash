#!/bin/bash

# Function to handle file changes
function handle_file_change {
  # Extract filename from the event data
  filename=$(echo "$1" | awk '{print $3}')
  
  # Check if the file matches the specified pattern
  if [[ $filename =~ $pattern ]]; then
    # Search the file for the specified string
    if grep -q "$search_string" "$filename"; then
      # Extract specific values from the line containing the string
      value=$(grep "$search_string" "$filename" | awk '{print $2}')
      
      # Create a backup of the file in the backup directory
      cp "$filename" "$backup_dir/$filename"
      
      # Replace the specified string with a new value
      sed -i "s/$search_string/$new_value/g" "$filename"
      
      # If the file has more than 10 lines, extract the first 5 and last 5 lines and save them to a separate file
      num_lines=$(wc -l < "$filename")
      if [[ $num_lines -gt 10 ]]; then
        head -n 5 "$filename" > "$filename.head"
        tail -n 5 "$filename" > "$filename.tail"
      fi
    fi
  fi
}

# Prompt the user for the directory path to monitor
read -p "Enter directory path to monitor: " dir_path

# Prompt the user for the regular expression pattern to match file names
read -p "Enter regular expression pattern to match file names: " pattern

# Validate the pattern
if ! [[ "$pattern" =~ $pattern ]]; then
  echo "Error: Invalid regular expression pattern"
  exit 1
fi

# Prompt the user for the search string
read -p "Enter search string: " search_string

# Prompt the user for the new value
read -p "Enter new value: " new_value

# Create the backup directory
backup_dir="$dir_path/backup"
if [[ -d "$backup_dir" ]]; then
  read -p "Backup directory already exists. Overwrite existing backup? [y/n]: " overwrite_backup
  if [[ $overwrite_backup == "y" ]]; then
    rm -rf "$backup_dir"
  else
    backup_dir="$dir_path/backup_$(date +%Y%m%d_%H%M%S)"
  fi
fi
mkdir "$backup_dir"

# Monitor the directory for changes using inotifywait
inotifywait -m -r -e create,modify,delete "$dir_path" |
  while read path action file; do
    # Call the handle_file_change function when a file change is detected
    handle_file_change "$path $action $file"
  done
