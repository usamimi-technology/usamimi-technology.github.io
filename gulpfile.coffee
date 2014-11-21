gulp        = require 'gulp'
cache       = require 'gulp-cache'
# TODO: よくわからないので要調査
# changed     = require 'gulp-changed'
coffee      = require 'gulp-coffee'
deploy      = require 'gulp-gh-pages'
gulpIf      = require 'gulp-if'
imagemin    = require 'gulp-imagemin'
minifyCss   = require 'gulp-minify-css'
minifyHtml  = require 'gulp-minify-html'
pleeease    = require 'gulp-pleeease'
plumber     = require 'gulp-plumber'
rename      = require 'gulp-rename'
rev         = require 'gulp-rev'
sass        = require 'gulp-ruby-sass'
size        = require 'gulp-size'
uglify      = require 'gulp-uglify'
useref      = require 'gulp-useref'
bower       = require 'bower'
browserSync = require 'browser-sync'
del         = require 'del'
runSequence = require 'run-sequence'

reload = browserSync.reload

dir =
  src: 'app'
  dist: 'build'
  tmp: '.tmp'
  scripts: 'scripts'
  styles: 'styles'
  bower: 'bower_components'
  fonts: 'fonts'
  images: 'images'

path =
  src:
    scripts: "#{dir.src}/#{dir.scripts}"
    styles: "#{dir.src}/#{dir.styles}"
    images: "#{dir.src}/#{dir.images}"
    fonts: "#{dir.src}/#{dir.fonts}"
  tmp:
    scripts: "#{dir.tmp}/#{dir.scripts}"
    styles: "#{dir.tmp}/#{dir.styles}"
    images: "#{dir.tmp}/#{dir.images}"
    fonts: "#{dir.tmp}/#{dir.fonts}"
  dist:
    scripts: "#{dir.dist}/#{dir.scripts}"
    styles: "#{dir.dist}/#{dir.styles}"
    images: "#{dir.dist}/#{dir.images}"
    fonts: "#{dir.dist}/#{dir.fonts}"
  bower:
    sass: [
      "#{dir.bower}/bootstrap-sass-official/assets/stylesheets"
    ]
    fonts: [
      "#{dir.bower}/fontawesome/fonts/"
      "#{dir.bower}/bootstrap-sass-official/assets/fonts/bootstrap/"
    ]

load_components = ->
  gulp.src "#{dir.bower}/bootstrap-sass-official/assets/stylesheets/_bootstrap.scss"
    .pipe rename 'style.scss'
    .pipe gulp.dest path.src.styles

  gulp.src "#{dir.bower}/bootstrap-sass-official/assets/stylesheets/bootstrap/_variables.scss"
    .pipe gulp.dest path.src.styles

  gulp.src path.bower.fonts
    .pipe gulp.dest path.tmp.fonts

gulp.task 'bower-init', ->
  bower.commands.install().on 'end', (r) -> load_components()

gulp.task 'bower-update', ->
  bower.commands.update().on 'end', (r) -> load_components()

gulp.task 'coffee', ->
  gulp.src "#{path.src.scripts}/**/*.coffee"
    .pipe plumber()
    .pipe coffee(bare: true)
    .pipe gulp.dest path.tmp.scripts

gulp.task 'sass', ->
  gulp.src "#{path.src.styles}/**/*.scss"
    .pipe plumber()
    .pipe sass(
      loadPath: path.bower.sass
      bundleExec: true
    )
    .pipe pleeease()
    .pipe gulp.dest path.tmp.styles

gulp.task 'images', ->
  gulp.src "#{path.src.images}/**/*"
    .pipe cache imagemin
      progressive: true
      interlaced: true
    .pipe gulp.dest path.dist.images
    .pipe size(title: 'images')

gulp.task 'fonts', ->
  gulp.src [
    "#{path.src.fonts}/**/*"
    "#{path.tmp.fonts}/**/*"
  ]
    .pipe gulp.dest path.dist.fonts
    .pipe size(title: 'fonts')

gulp.task 'server', ->
  browserSync.init
    server:
      baseDir: [dir.src, dir.tmp, '.']

gulp.task 'watch', ->
#  gulp.watch "#{dir.src}/**/*.html", reload
  gulp.watch "#{path.src.styles}/**/*.{scss,css}", ['sass', reload]
  gulp.watch "#{path.src.scripts}/**/*.{coffee,js}", ['coffee', reload]
  gulp.watch "#{path.src.images}/**/*", reload

gulp.task 'html', ->
 assets = useref.assets(searchPath: [dir.src, dir.tmp, '.'])
 gulp.src "#{dir.src}/**/*.html"
   .pipe assets
   .pipe gulpIf('*.js', uglify())
   .pipe gulpIf('.css', minifyCss())
   .pipe assets.restore()
   .pipe useref()
   .pipe gulpIf('*.html', minifyHtml())
   .pipe gulp.dest dir.dist
   .pipe size(title: 'html')

gulp.task 'clean', ->
  del.bind null, [dir.tmp, dir.dist], { dot: true }

gulp.task 'deploy', ->
  gulp.src "#{dir.dist}/**/*"
    .pipe deploy
      branch: 'master'

gulp.task 'build', ['clean'], (cb) ->
  runSequence ['coffee', 'sass'], ['html', 'images', 'fonts'], 'deploy', cb

gulp.task 'buildDev', ['coffee', 'sass']
gulp.task 'default', ['buildDev', 'server', 'watch']
