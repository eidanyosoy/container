$(document).ready(function () {
    function handleInProgressJobs() {
        $.getJSON("srv/api/jobs/inprogress.php", function (json) {
            inProgressTableBody = $('#uploadsTable > tbody');

            totalDownloadRate = 0;
            downloadRateType = null;

            inProgressTableBody.empty();
            if (json.jobs === null) {
                inProgressTableBody.append('<tr><td class="text-muted" colspan="5">No entries found.</td></tr>');
                return;
            }
            $.each(json.jobs, function (job, data) {
                inProgressTableBody.append(`<tr><td class="truncate">${data.file_name}</td><td class="d-none d-lg-table-cell">${data.gdsa}</td>
                        <td>
                            <div class="progress">
                                <div class="progress-bar bg-secondary bg-gradient text-light" role="progressbar"
                                     style="width: ${data.upload_percentage};" aria-valuenow="${data.upload_percentage}" aria-valuemin="0" aria-valuemax="100">${data.upload_percentage}
                                </div>
                            </div>
                        </td>
                        <td class="d-none d-lg-table-cell">${data.file_size}</td><td class="text-end">${data.upload_remainingtime} (with ${data.upload_speed})</td></tr>`)

                if (data.upload_speed != null) {
                    var rateMatches = data.upload_speed.match(/([0-9+\.]+)([MKG])/);
                    totalDownloadRate += Number(rateMatches[1]);
                }
            });

            $('#download_rate').empty();
            totalDownloadRate = totalDownloadRate.toFixed(2);
            if (totalDownloadRate < 5) {
                $('#download_rate').append(`<span class="badge bg-danger text-dark">${totalDownloadRate}</span>`)
            } else if (totalDownloadRate < 10) {
                $('#download_rate').append(`<span class="badge bg-warning text-dark">${totalDownloadRate}</span>`)
            } else {
                $('#download_rate').append(`<span class="badge bg-success text-dark">${totalDownloadRate}</span>`)
            }
        });
    }

    function handleCompletedJobList() {
        completedTableBody = $('#completedTable > tbody');
        $('#page').pagination({
            dataSource: 'srv/api/jobs/completed.php',
            locator: 'jobs',
            ulClassName: 'pagination',
            totalNumberLocator: function (response) {
                return response.total_count;
            },
            pageSize: $('#pageSize > li.page-item.active > a').text() ?? 10,
            beforePaging: function (e) {
                // function allows us to en-/disable the refresh if page != 1
                if (!isNaN(e) && e === 1) {
                    if (window.completedInterval === undefined) {
                        window.completedInterval = setInterval(handleCompletedJobList, 5000)
                    }
                } else {
                    clearInterval(window.completedInterval)
                    window.completedInterval = null;
                }
            },
            callback: function (data, pagination) {
                $('#page').find('ul').children('li').addClass("page-item");
                $('#page').find('ul').children('li').children('a').addClass("page-link");

                jobs = data;

                completedTableBody.empty();
                if (jobs === null) {
                    completedTableBody.append('<tr><td class="text-muted" colspan="4">No entries found.</td></tr>');
                    return;
                }
                $.each(jobs, function (job, data) {
                    completedTableBody.append(`<tr><td>${data.file_name}</td><td>${data.gdsa}</td><td>${data.file_size}</td><td>${data.time_elapsed ?? 'n/a'}</td></tr>`);
                });
            }
        })
    }

    //Register listener on pagesize
    $('#pageSize > li.page-item').click(function (event) {
        t = jQuery(this);
        $('#pageSize > li.page-item.active').removeClass('active');
        t.addClass('active');
        handleCompletedJobList();
    })

    //Initialize handling of "completed jobs"
    handleCompletedJobList();
    handleInProgressJobs();
    setInterval(handleInProgressJobs, 1000);
});