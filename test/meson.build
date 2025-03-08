unit_tests = [

]
foreach unit_test : unit_tests
  test_exe = executable(unit_test, unit_test + '.vala',
    dependencies: [gtkcal_deps, gtkcal_lib_dep],
    link_with: gtkcal_lib,
    include_directories: include_directories('../src'),
  )
  test(unit_test, test_exe)
endforeach


test_app = executable('test_app', 'app.vala',
  dependencies: [gtkcal_deps, gtkcal_lib_dep],
  link_with: gtkcal_lib,
  include_directories: include_directories('../src'),
  install: false,
)

test_simple = executable('test_simple', 'test.vala',
  dependencies: [gtkcal_deps, gtkcal_lib_dep],
  link_with: gtkcal_lib,
  include_directories: include_directories('../src'),
  install: false,
)