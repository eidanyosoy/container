<?php
include_once('../../../settings.php');
include_once('../../entities/ApiResponse.php');
include_once('../../entities/UploadJobStatus.php');
include_once('../../utility.php');

function processJsonFiles()
{
    $jsonDirectoryIterator = new FilesystemIterator(JSON_DIRECTORY_INPROGRESS);
    $response = new ApiResponse();
    foreach ($jsonDirectoryIterator as $jsonFile) {
        if (!$jsonFile->isFile() || str_starts_with(basename($jsonFile), '.')) {
            continue;
        }
        $jsonObject = json_decode(file_get_contents($jsonFile));
        try {
            $jobStatus = new UploadJobStatus();
            $jobStatus->job_last_update_timestamp = $jsonFile->getMTime();
            $jobStatus->job_name = basename($jsonFile);
            $jobStatus->gdsa = $jsonObject->gdsa;
            $jobStatus->file_directory = $jsonObject->filedir;
            $jobStatus->file_name = $jsonObject->filebase;
            $jobStatus->file_size = $jsonObject->filesize;

            //Parse rclone logfile
            mapLogFileInformation($jsonObject->logfile, $jobStatus);

            $response->jobs[] = $jobStatus;
        } catch (Exception $e) {
            //TODO: Error handling
        }
    }

    $response->total_count = isset($response->jobs) ? count($response->jobs) : 0;

    return json_encode($response);
}

function mapLogFileInformation($logfile, UploadJobStatus $jobStatus): UploadJobStatus
{
    $logBlock = readLastLines($logfile, 6, true);
    preg_match('/([0-9\%]+)\s\/\d+\.\d+\w{1,2}\,\s(\d+.\d+\w+\/s)\,\s([0-9dhms]+)/', $logBlock, $matches);
    if ($matches) {
        $jobStatus->upload_percentage = $matches[1];
        $jobStatus->upload_speed = $matches[2];
        $jobStatus->upload_remainingtime = $matches[3];
    } else {
        //Did not find any matches. It's likely to be a complete new upload
        $jobStatus->upload_percentage = '0%';
    }
    return $jobStatus;
}

/** actual logic */
header('Content-Type: application/json; charset=utf-8');
echo processJsonFiles();
