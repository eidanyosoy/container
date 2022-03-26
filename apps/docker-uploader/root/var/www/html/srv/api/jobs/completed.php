<?php
include_once('../../../settings.php');
include_once('../../entities/ApiResponse.php');
include_once('../../entities/UploadJobStatus.php');
include_once('../../utility.php');

function processJsonFiles()
{
    $jsonDirectoryIterator = new FilesystemIterator(JSON_DIRECTORY_COMPLETED);
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

            $jobStatus->time_end = $jsonObject->endtime;
            $jobStatus->time_start = $jsonObject->starttime;
            $jobStatus->time_elapsed = secs_to_str($jobStatus->time_end - $jobStatus->time_start);
            $response->jobs[] = $jobStatus;
        }catch (Exception $e) {
            //TODO: Error handling.. logfile?
        }
    }

    //Check GET parameter..
    $total_records = sizeof($response->jobs);
    $response->total_count = $total_records; // Save total completed job count to let frontend calculate pagination
    if ($response->jobs != null && isset($_GET["pageNumber"]) && isset($_GET["pageSize"])
        && is_numeric($_GET["pageNumber"]) && is_numeric($_GET["pageSize"]) && $total_records > 10) {
        //Order the array from "newest" -> "oldest"
        usort($response->jobs, "sortByLastUpdateTimestamp");

        $current_page = intval($_GET["pageNumber"]);
        $page_size =  intval($_GET["pageSize"]);
        $total_pages   = ceil($total_records / $page_size);
        // Validate parameters and default them if necessary
        if ($current_page > $total_pages) {
            $current_page = $total_pages;
        }
        if ($current_page < 1) {
            $current_page = 1;
        }
        if ($page_size > 50 || $page_size < 1) {
            $page_size = 10;
        }

        // Slice the data
        $offset = ($current_page - 1) * $page_size;
        $response->jobs = array_slice($response->jobs, $offset, $page_size);
    }

    return json_encode($response);
}

function sortByLastUpdateTimestamp($a, $b)
{
    return $a->job_last_update_timestamp == $b->job_last_update_timestamp ?
        0 : ($b->job_last_update_timestamp > $a->job_last_update_timestamp ?
            1 : ($b->job_last_update_timestamp < $a->job_last_update_timestamp ?
                -1 : null));
}

function mapCommonAttributes($jsonObject, UploadJobStatus $jobStatus): UploadJobStatus
{
    $jobStatus->gdsa = $jsonObject->gdsa;
    $jobStatus->file_directory = $jsonObject->filedir;
    $jobStatus->file_name = $jsonObject->filebase;
    $jobStatus->file_size = $jsonObject->filesize;
    $jobStatus->status = $jsonObject->status;

    return $jobStatus;
}

/** actual logic */
header('Content-Type: application/json; charset=utf-8');
echo processJsonFiles();
