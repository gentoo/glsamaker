const webpack = require('webpack');
const path = require('path');

module.exports = {
    entry: {
        stylesheets: './web/packs/stylesheets.js',
        application: './web/packs/application.js',
        account: './web/packs/account.js',
        edit: './web/packs/edit.js',
        glsa: './web/packs/glsa.js',
        newglsa: './web/packs/newglsa.js',
        statistics: './web/packs/statistics.js',
        admin: './web/packs/admin.js',
    },
    output: {
        path: path.resolve(__dirname, 'assets'),
        filename: '[name].js',
    },
    plugins: [
        require('postcss-import')
    ],
    module: {
        rules: [
            {
                test: /\.css$/i,
                use: [
                    // Creates `style` nodes from JS strings
                    'style-loader',
                    // Translates CSS into CommonJS
                    {
                        loader: 'css-loader',
                    },{
                        loader: 'resolve-url-loader',
                    },
                ],
            },
            {
                test: /\.s[ac]ss$/i,
                use: [
                    // Creates `style` nodes from JS strings
                    'style-loader',
                    // Translates CSS into CommonJS
                    {
                        loader: 'css-loader',
                    },{
                        loader: 'resolve-url-loader',
                    },
                    // Compiles Sass to CSS
                    {
                        loader: 'sass-loader',
                        options: {
                            sourceMap: true,
                        }
                    },
                ],
            },
            {
                test: /\.(woff(2)?|ttf|eot|svg)(\?v=\d+\.\d+\.\d+)?$/,
                use: [
                    {
                        loader: 'file-loader',
                        options: {
                            name: '[name].[ext]',
                            publicPath: '/assets'
                        }
                    }
                ]
            },
            {
                test: /datatables\.net(?!.*[.]css$).*/,
                loader: 'imports-loader?define=>false'
            }
        ],
    },
    plugins: [
        new webpack.ProvidePlugin({
            $: 'jquery',
            jQuery: 'jquery',
            'window.jQuery': 'jquery',
            'window.$': 'jquery',
            'windows.jQuery': 'jquery',
            tether: 'tether',
            Tether: 'tether',
            'window.Tether': 'tether',
            Popper: ['popper.js', 'default'],
            'window.Tether': 'tether',
            Modal: 'exports-loader?Modal!bootstrap/js/dist/modal',
        }),
    ],
};
