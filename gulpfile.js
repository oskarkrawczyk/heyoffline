var gulp = require("gulp");
var browserSync = require("browser-sync");
var bsInjector = require("bs-snippet-injector");

var options = {
  browsersync: {
    open: false,
    // xip: false,
    port: 3001,
    socket: {
      port: 3003,
    },
    ui: {
      port: 3002,
    },
    server: {
      baseDir: "./",
    },
  }
};

gulp.task("watch", () => {
  browserSync.init(options.browsersync);
});
