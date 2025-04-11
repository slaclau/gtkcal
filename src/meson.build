gtkcal_deps = [
  config_dep,
  dependency('gtk4'),
  dependency('libadwaita-1'),
  dependency('gee-0.8'),
  dependency('libical-glib', version: '>= 1.0'),
  dependency('libsoup-3.0'),
  dependency('gweather4'),
  dependency('libgeoclue-2.0'),
  valac.find_library('posix'),
  cc.find_library('m'),
]

subdir('gui')
subdir('weather')

gtkcal_sources += files([
  'enums.vala',
  'utils.vala',
  'date-time-utils.vala',
  'GtkCalTimer.vala',
])
foreach src : gtkcal_sources
  message(src.full_path())
endforeach

gtkcal_lib = shared_library('gtkcal-' + major_minor, gtkcal_sources + resources,
  dependencies: gtkcal_deps,
  include_directories: config_inc,
  install: true,
  vala_vapi: 'GtkCal-' + major_minor + '.vapi',
  vala_gir: 'GtkCal-' + major_minor + '.gir',
  install_dir: [true, true, true, true],
)

g_ir_compiler = find_program('g-ir-compiler')
custom_target('gtkcal_typelib',
  command: [
    g_ir_compiler,
    '--output', '@OUTPUT@',
    '--shared-library', 'libgtkcal-' + major_minor + '.so',
    meson.current_build_dir() / 'GtkCal-' + major_minor + '.gir'
  ],
  output: 'GtkCal-' + major_minor + '.typelib',
  depends: gtkcal_lib,
  install: true,
  install_dir: get_option('libdir') / 'girepository-1.0',
)

gtkcal_lib_dep = declare_dependency(
  link_with: gtkcal_lib,
  dependencies: gtkcal_deps,
  include_directories: config_inc,
)

main_build_dir = meson.current_build_dir()
