project('gtkcal', ['c', 'vala'],
          version: '0.1.0',
    meson_version: '>= 1.4.0',
  default_options: [ 'warning_level=1', 'werror=false', ],
)

version_components = meson.project_version().split('.')
major_minor = version_components[0] + '.' + version_components[1]

i18n = import('i18n')
gnome = import('gnome')
valac = meson.get_compiler('vala')
cc = meson.get_compiler('c')

valadoc = find_program('valadoc', required: get_option('docs'))

srcdir = meson.project_source_root() / 'src'

config_h = configuration_data()
config_h.set_quoted('PACKAGE_VERSION', meson.project_version ())
config_h.set_quoted('GETTEXT_PACKAGE', 'gtkcal')
config_h.set_quoted('LOCALEDIR', get_option('prefix') / get_option('localedir'))
configure_file(output: 'config.h', configuration: config_h)

config_dep = valac.find_library ('config', dirs: srcdir)
config_inc = include_directories('.')

add_project_arguments('-DGETTEXT_PACKAGE="' + meson.project_name () + '"', language: 'c')
add_project_arguments('-DLIBICAL_GLIB_UNSTABLE_API', language: 'c')

#add_project_arguments('-DENABLE_TRACE', language: 'c')

gtkcal_sources = []
resources = gnome.compile_resources('gtkcal-resources',
  'data/gtkcal.gresource.xml',
  source_dir: ['data']
)

subdir('src')
subdir('po')
subdir('test')
subdir('docs')
