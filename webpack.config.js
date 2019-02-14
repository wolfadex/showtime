const path = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');

module.exports = ({ isDev } = {}) => {
  return {
    mode: isDev ? 'development' : 'production',
    entry: path.join(__dirname, 'src/index.js'),
    output: {
      path: path.join(__dirname, 'dist'),
      filename: 'bundle.js',
    },
    module: {
      rules: [
        {
          exclude: /node_modules|elm-stuff/,
          test: /\.js$/,
          use: {
            loader: 'babel-loader',
            options: {
              presets: ['@babel/preset-env'],
            },
          },
        },
        {
          exclude: /node_modules|elm-stuff/,
          test: /\.elm$/,
          use: {
            loader: 'elm-webpack-loader',
          },
        },
        {
          test: /\.css$/,
          use: 'css-loader'
        }
      ],
    },
    plugins: [
      new HtmlWebpackPlugin({
        template: './src/index.html'
      })
    ],
    devServer: {
      port: 8000
    }
  };
};
