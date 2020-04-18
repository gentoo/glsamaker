

function initDatatable(){
    if (window.DraftsDataTables.length === 0 && $('.drafts-data-table').length !== 0) {
        $('.drafts-data-table').each((_, element) => {

            var table = $(element).DataTable( {
                "order": [[ 0, "desc" ]],
                "paging":   true,
                "ordering": true,
                "searching": true,
                "info":     true,
                "lengthChange":     false,
                "language": {
                    "emptyTable": "Currently there are no drafts available. -- Start with creating one."
                }
            });

            window.DraftsDataTables.push(table);

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
    while (window.DraftsDataTables.length !== 0) {
        window.DraftsDataTables.pop().destroy();
    }
}

export default {initDatatable, destroyDatatable}
