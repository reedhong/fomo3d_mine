module.exports = {
    mode: 'production',
    entry:  __dirname + "/src/js/srcbd.js",//已多次提及的唯一入口文件
    output: {
      path: __dirname + "/src/js/",//打包后的文件存放的地方
      filename: "bundle.js"//打包后输出文件的文件名
    }
  }