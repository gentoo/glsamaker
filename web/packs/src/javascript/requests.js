
function initDatatable(){
    if (window.RequestsDataTables.length === 0 && $('.requests-data-table').length !== 0) {
        $('.requests-data-table').each((_, element) => {

            var table = $(element).DataTable( {
                "order": [[ 0, "desc" ]],
                "paging":   true,
                "ordering": true,
                "searching": true,
                "info":     true,
                "lengthChange":     false,
                "language": {
                    "emptyTable": "Currently there are no requests available. -- Start with filling one."
                }
            });

            window.RequestsDataTables.push(table);

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
    while (window.RequestsDataTables.length !== 0) {
        window.RequestsDataTables.pop().destroy();
    }
}

export default {initDatatable, destroyDatatable}
