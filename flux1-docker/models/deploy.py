import os
import sys
import json
import logging
import aiohttp
import asyncio
from tqdm.asyncio import tqdm

# Logging configuration
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Semaphore to limit the number of concurrent downloads
sem = asyncio.Semaphore(2)

# Helper functions
def is_truthy(value):
    """
    Checks if the given value is truthy.
    """
    return value.lower() in ['true', '1', 'yes']

def get_project_root():
    """
    Gets the project root directory from the environment variable PROJECT_ROOT.
    If not set, defaults to the current directory.
    """
    return os.getenv('PROJECT_ROOT', './')

def get_override_models():
    """
    Gets whether to override existing models from the environment variable OVERRIDE_MODELS.
    If not set, defaults to False.
    """
    return os.getenv('OVERRIDE_MODELS', False)

def get_model_config_path():
    """
    Gets the path to the model configuration file from the environment variable MODEL_CONFIG_PATH.
    If not set, defaults to './config.json'.
    """
    return os.getenv('MODEL_CONFIG_PATH', './config.json')

def get_before_deploy_cmd():
    """
    Gets the start command from the environment variable BEFORE_DEPLOY_CMD.
    """
    return os.getenv('BEFORE_DEPLOY_CMD', False)

def get_after_deploy_cmd():
    """
    Gets the start command from the environment variable AFTER_DEPLOY_CMD.
    """
    return os.getenv('AFTER_DEPLOY_CMD', False)

def get_download_location(location):
    """
    Resolves the download location, interpreting the "@" symbol as the project root.
    """
    if location.startswith('@'):
        location = location.replace('@', get_project_root(), 1)
    return os.path.abspath(location)

async def download_file(url, dest):
    """
    Asynchronously downloads a file from the given URL to the specified destination with a progress bar.
    """
    os.makedirs(os.path.dirname(dest), exist_ok=True)

    async with aiohttp.ClientSession() as session:
        async with session.get(url) as response:
            total_size = int(response.headers.get('content-length', 0))
            with open(dest, 'wb') as file:
                with tqdm(
                    desc=os.path.basename(dest),
                    total=total_size,
                    unit='B',
                    unit_scale=True,
                    unit_divisor=1024,
                    ncols=100
                ) as bar:
                    async for data in response.content.iter_chunked(1024):
                        file.write(data)
                        bar.update(len(data))

async def download_file_with_semaphore(origin, destination_path):
    async with sem:
        await download_file(origin, destination_path)

# Main function
async def main():
    logging.info(" ====================================")
    logging.info(" |                                  |")
    logging.info(" | Model Deployment                 |")
    logging.info(" | by TD99                          |")
    logging.info(" |                                  |")
    logging.info(" ====================================")

    # Run before deploy command
    start_cmd = get_before_deploy_cmd()
    if start_cmd:
        logging.warning(f"Running the command: {start_cmd}")
        exit_code = os.system(start_cmd)
        if exit_code != 0:
            logging.error(f"Command failed with exit code {exit_code}. Exiting...")
            sys.exit(exit_code)

    logging.info("Starting model deployment...")

    # Read config
    with open(get_model_config_path(), 'r') as f:
        config = json.load(f)

    async with aiohttp.ClientSession() as session:
        tasks = []
        for model in config:
            # Get download location
            download_location = get_download_location(model['location'])
            destination_path = os.path.join(download_location, model['name'])

            # Check if model already exists and skip
            if os.path.exists(destination_path) and not is_truthy(get_override_models()):
                logging.info(f"Model already exists at {destination_path}, skipping download.")
                continue

            # Download the model
            tasks.append(download_file_with_semaphore(model['origin'], destination_path))

        # Run all download tasks concurrently
        await asyncio.gather(*tasks)
    logging.info("Model deployment completed.")

    # Run after deploy command
    start_cmd = get_after_deploy_cmd()
    if start_cmd:
        logging.warning(f"Running the command: {start_cmd}")
        exit_code = os.system(start_cmd)
        if exit_code != 0:
            logging.error(f"Command failed with exit code {exit_code}. Exiting...")
            sys.exit(exit_code)
    
    # Exit
    logging.info("Exiting...")
    sys.exit(0)

if __name__ == "__main__":
    asyncio.run(main())