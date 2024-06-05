#!/bin/bash
CONFIG_FILE="./config/config.json" # Path to your config.json file

# Function to update JSON values
update_json() {
    key="$1"
    value="$2"
    jq --arg key "$key" --arg val "$value" '(.[$key]) = $val' $CONFIG_FILE > temp.$$.json && mv temp.$$.json $CONFIG_FILE
}

# Function to update JSON values, where the value is a raw JSON rather than a string
update_dns() {
    key="$1"
    value="$2"
    jq --arg key "$key" --argjson val "$value" '(.[$key]) = $val' $CONFIG_FILE > temp.$$.json && mv temp.$$.json $CONFIG_FILE
}

# Function to update use_aws_profile based on if the user provided a profile or access key
update_use_aws_profile() {
    if [ -n "$1" ]; then
        update_json "use_aws_profile" "true"
    else
        update_json "use_aws_profile" "false"
    fi
}

# Initialize the starting configuration
cp ./config/config_default.json $CONFIG_FILE 

# Mandatory variables
declare -A variables=(
    ["region_master"]="Type the region"
    ["index_document"]="Type your html file name xxxx.html"
    ["error_document"]="Type your error html file name xxxx.html"
)

# Optional variables
declare -A optional_variables=(
    ["endpoint"]="API Endpoint"
    ["basic_dynamodb_table"]="Basic DynamoDB Table"
    ["function_name"]="Lambda Function Name"
    ["runtime"]="Lambda Runtime"
)

# Prompt the user for the AWS profile
echo "To use an AWS profile, enter the profile name                      (or type 'none' to specify Access Keys instead):"
read aws_profile

if [[ $aws_profile != "none" ]]; then
    # The user chose to use an AWS profile
    
    # Check if the variable is empty
    if [ -z "$aws_profile" ]; then
        aws_profile="default"
    fi
    update_json "profile" "$aws_profile"
    update_use_aws_profile "profile" # Set use_aws_profile to true
    echo "AWS Profile updated to $aws_profile."
else
    # The user chose to use AWS Access Keys
    echo "AWS Access Key ID:"
    read aws_access_key_id

    echo "AWS Secret Access Key:"
    read -s aws_secret_access_key
    
    # Update keys in the configuration
    if [[ -n $aws_access_key_id ]] && [[ -n $aws_secret_access_key ]]; then
        update_json "aws_access_key_id" "$aws_access_key_id"
        update_json "aws_secret_access_key" "$aws_secret_access_key"
        update_use_aws_profile "" # Set use_aws_profile to no as keys were provided
        update_json "profile" "default"
        echo "AWS access keys updated."
    else
        echo "Invalid input for AWS access keys. Exiting script."
        exit 1
    fi
fi

# Now, at this point in your script, we check if the user has a custom domain:
read -p "Do you have a custom domain? (yes/no): " custom_domain_answer

if [[ $custom_domain_answer == "yes" ]]; then
    read -p "Please enter your DNS Name:" dns_input
    update_json "dns" "$dns_input"
    update_json "custom_domain_exists" "true"
    echo "DNS updated to $dns_input"
else
    update_json "custom_domain_exists" "false"
    # We do not prompt for DNS name and leave "dns" as an empty string.
    update_json "dns" ""
fi


# Update remaining mandatory variables
for key in "${!variables[@]}"
do
    if [[ ${variables[$key]} ]]; then
        current_value=$(jq -r ".$key" $CONFIG_FILE)
        echo "${variables[$key]} (Current: $current_value):"
        read new_value
        if [[ -n $new_value ]]; then
            update_json "$key" "$new_value"
            echo "$key updated to $new_value."
        fi
    fi
done


echo "Do you want to modify optional parameters? This is not critical to the process (yes/no):"
read modify_optional

if [[ "$modify_optional" == "yes" ]]; then
    for key in "${!optional_variables[@]}"
    do
        current_value=$(jq -r ".$key" $CONFIG_FILE)
        echo "${optional_variables[$key]} (Current: $current_value):"
        read new_value
        if [ ! -z "$new_value" ]; then
            # Ensure new values are properly escaped as JSON strings
            update_json "$key" "$new_value"
            echo "$key updated to $new_value."
        fi
    done
fi

# Ask the user if they want to manually update files.
read -p "Choose yes if you have a github with your resume code? (yes/no): " manual_update

if [[ $manual_update == "yes" ]]; then
    # Prompt for repository URL if the user did not choose to manually update files.
    read -p "Please enter the repository URL of your static website code: " repo_url

    # Define the directory where you want to clone the repository.
    static_site_dir="./static_website/html"

    # Define a temporary directory for cloning.
    temp_dir="./temp_repo"

    # Attempt to clone the repository into the temporary directory.
    git clone "$repo_url" "$temp_dir" 2> /dev/null

    if [ -d "$temp_dir/.git" ]; then
        echo "Repository cloned successfully."
        
        rm -rf $static_site_dir  # Remove the existing static_site_dir if needed.
        
        mkdir -p $static_site_dir  # Ensure the static_site_dir exists.
        mv -f $temp_dir/* $static_site_dir/  # Move content.
        
        rm -rf $temp_dir  # Clean up temp dir.
        
        echo "Static website code has been updated successfully."
    else
        echo "Failed to clone the repository. Please check the repository URL and try again."
        
        # Clean up the attempt.
        rm -rf $temp_dir
    fi
else
    default_repo_url=$(jq -r ".default_code_repository" $CONFIG_FILE)
    echo "${default_repo_url}"
    
    # Define the directory where you want to clone the repository, like before.
    static_site_dir="./static_website/html"
    
    # Define a temporary directory for cloning.
    temp_dir="./temp_repo"
    
    # Make sure the directory is empty before cloning the new repository.
    rm -rf $temp_dir
    mkdir -p $temp_dir
    rm -rf $static_site_dir
    mkdir -p $static_site_dir
    
    # Clone the repository from the default URL into the temporary directory.
    git clone $default_repo_url $temp_dir 2> /dev/null
    
    # Validate that the repository was cloned correctly.
    if [ -d "$temp_dir/.git" ]; then
        echo "Default repository cloned successfully."
        
        # Move the content from the temporary directory to the static site directory.
        mv -f $temp_dir/* $static_site_dir/
        
        # Remove the temporary directory as we no longer need it.
        rm -rf $temp_dir
        
        echo "Static website code has been updated with the default code repository."
    else
        echo "Failed to clone the default repository. Please check the repository URL and try again."
    fi
fi

dns_value=$(jq -r ".dns" $CONFIG_FILE)

# Check if the dns_value is not empty
if [[ -n "$dns_value" ]]; then
    # Read the current dns_cors values
    current_dns_cors=$(jq '.dns_cors' $CONFIG_FILE)

    # This will add the "https://" prefix if it's required
    full_dns_value="https://$dns_value"

    # Append the new value if it is not already in the array
    if ! $(echo $current_dns_cors | jq --arg v "$full_dns_value" 'index($v)'); then
        updated_dns_cors=$(echo $current_dns_cors | jq --arg v "$full_dns_value" '. + [ $v ]')

        # Call update_json with the newly constructed JSON array
        update_json "dns_cors" "$updated_dns_cors"
    fi
fi

echo "Configuration update complete."