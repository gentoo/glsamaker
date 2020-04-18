
function initDatatable(){
    if (window.ArchivesDataTables.length === 0 && $('.archives-data-table').length !== 0) {
        $('.archives-data-table').each((_, element) => {

            var table = $(element).DataTable( {
                "order": [[ 0, "desc" ]],
                "paging":   true,
                "ordering": true,
                "searching": true,
                "info":     true,
                "lengthChange":     false,
                "language": {
                    "emptyTable": "Currently there are no GLSAs available. -- Start with releasing one."
                },
                "columnDefs": [
                    {
                        "targets": 'hide',
                        "visible": false
                    }],
            });

            window.ArchivesDataTables.push(table);

            // Add event listener for opening and closing details
            $('#table_id tbody').on('click', 'td', function () {
                var tr = $(this).closest('tr');
                var row = table.row( tr );
                Turbolinks.visit("/glsa/" + row.data()[0]);
            } );

        });
    }
}

function destroyDatatable(){
    while (window.ArchivesDataTables.length !== 0) {
        window.ArchivesDataTables.pop().destroy();
    }
}

export default {initDatatable, destroyDatatable}
