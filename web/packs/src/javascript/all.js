
function initDatatable(){
    if (window.AllDataTables.length === 0 && $('.all-data-table').length !== 0) {
        $('.all-data-table').each((_, element) => {

            var table = $(element).DataTable( {
                "order": [[ 0, "desc" ]],
                "paging":   true,
                "ordering": true,
                "searching": true,
                "info":     true,
                "lengthChange":     false,
                "language": {
                    "emptyTable": "Currently there are no glsas available. -- Start with filling one."
                }
            });

            window.AllDataTables.push(table);

            // Add event listener for opening and closing details
            $('#table_id tbody').on('click', 'td', function () {
                var tr = $(this).closest('tr');
                var row = table.row( tr );
                Turbolinks.visit("/glsa/" + row.data()[0]);
            } );

        });
    }
}

function destroyDatatable() {
    while (window.AllDataTables.length !== 0) {
        window.AllDataTables.pop().destroy();
    }
}

export default {initDatatable, destroyDatatable}
