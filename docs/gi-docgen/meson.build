gidocgen = find_program('gi-docgen', required: get_option('docs'), native: true)

custom_target('gi-docgen',
  output: 'gtkcal-' + major_minor,
  command: [
    gidocgen,
    'generate',
    '--no-namespace-dir',
    main_build_dir / 'GtkCal-' + major_minor + '.gir',
    '--output-dir', '@OUTPUT@' ,
  ],
  depends: gtkcal_lib,
  build_by_default: true,
  install: true,
  install_dir: get_option('datadir') / 'doc',
)
