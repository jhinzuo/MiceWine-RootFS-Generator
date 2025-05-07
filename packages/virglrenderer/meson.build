#############################################################################
#
# Copyright (C) 2019 Collabora Ltd
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#

project(
   'virglrenderer', 'c',
   version: '1.0.1',
   license : 'MIT',
   meson_version : '>= 0.55',
   default_options : ['buildtype=release', 'b_ndebug=if-release',
                      'warning_level=3', 'c_std=gnu11']
)

# To change only before doing a release:
#
# 1. Incrememnt the revision
# 2. If the interface was changed in an compatible way increment the
#    interface age
# 3. If the ABI has changed in an incompatible way increment the binary_age
#    and set revision and interface_age to zero
binary_age    = 1
interface_age = 8
revision      = 9

virgl_version = meson.project_version()
version_array = virgl_version.split('.')
virgl_major_version = version_array[0].to_int()
virgl_minor_version = version_array[1].to_int()
virgl_micro_version = version_array[2].to_int()

cc = meson.get_compiler('c')

if cc.get_id() == 'gcc' and cc.version().version_compare('< 4.1')
  error('When using GCC, version 4.1 or later is required.')
endif

warnings = [
   '-Werror=enum-int-mismatch',
   '-Werror=implicit-function-declaration',
   '-Werror=missing-prototypes',
   '-Werror=pedantic',
   '-Wmissing-prototypes',
   '-Werror=incompatible-pointer-types',
   '-Werror=int-to-pointer-cast',
   '-Werror=switch',
   '-Wno-overlength-strings',
   '-Wno-missing-field-initializers',
]

add_project_arguments(cc.get_supported_arguments(warnings), language : 'c')

flags = [
   '-fvisibility=hidden',
]

add_project_arguments(cc.get_supported_arguments(flags), language : 'c')

prog_python = import('python').find_installation('python3')

not_found = dependency('', required: false)
libdrm_dep = dependency('libdrm', version : '>=2.4.50', required: get_option('drm').enabled() or get_option('venus'))
gbm_dep = not_found
thread_dep = dependency('threads')
epoxy_dep = dependency('epoxy', version: '>= 1.5.4')
m_dep = cc.find_library('m', required : false)

conf_data = configuration_data()
conf_data.set('VERSION', meson.project_version())
conf_data.set('_GNU_SOURCE', 1)
# Compile unstable APIs unconditionally to avoid building two variants of
# the lib. It's up to virglrenderer users to decide whether to use these
# APIs. Unstable APIs may be changed or removed without a notice.
conf_data.set('VIRGL_RENDERER_UNSTABLE_APIS', 1)
conf_data.set('ENABLE_DRM', libdrm_dep.found())

pkg_cflags = []

has_attribute_cleanup = cc.compiles('''
   void func(void *v) {}
   int main ()
   {
      void *foo __attribute__((cleanup (func))) = 0;
   }''')

with_tracing = get_option('tracing')

if with_tracing != 'none'
   if not has_attribute_cleanup
      error('Tracing requires compiler support for __attribute__((cleanup))')
   endif
endif

if with_tracing == 'percetto'
   # percetto uses C++ internally, so we need to link with C++.
   # TODO: remove -lstdc++ when percetto is a shared library.
   add_project_link_arguments('-lstdc++', language : 'c')
   percetto_dep = dependency('percetto', version : '>=0.0.8')
   conf_data.set('ENABLE_TRACING', 'TRACE_WITH_PERCETTO')
endif

if with_tracing == 'perfetto'
   vperfetto_min_dep = dependency('vperfetto_min')
   conf_data.set('ENABLE_TRACING', 'TRACE_WITH_PERFETTO')
endif

if with_tracing == 'sysprof'
   sysprof_dep = dependency('sysprof-capture-4', version: '>= 3.38.0')
   conf_data.set('ENABLE_TRACING', 'TRACE_WITH_SYSPROF')
endif

if with_tracing == 'stderr'
   conf_data.set('ENABLE_TRACING', 'TRACE_WITH_STDERR')
endif

if cc.has_header('sys/uio.h')
   conf_data.set('HAVE_SYS_UIO_H', 1)
endif

if cc.has_header('dlfcn.h')
   conf_data.set('HAVE_DLFCN_H', 1)
endif

with_host_windows = host_machine.system() == 'windows'

if thread_dep.found() and not with_host_windows
  conf_data.set('HAVE_PTHREAD', 1)
  if host_machine.system() != 'netbsd' and cc.has_function(
      'pthread_setaffinity_np',
      dependencies : thread_dep,
      prefix : '#include <pthread.h>',
      args : '-D_GNU_SOURCE')
    conf_data.set('HAVE_PTHREAD_SETAFFINITY', 1)
  endif
endif

if cc.has_header('sys/eventfd.h')
   conf_data.set('HAVE_EVENTFD_H', 1)
endif

if cc.has_header('sys/select.h')
  conf_data.set('HAVE_SYS_SELECT_H', 1)
endif

foreach b : ['bswap32', 'bswap64', 'clz', 'clzll', 'expect', 'ffs', 'ffsll',
             'popcount', 'popcountll', 'types_compatible_p', 'unreachable']
  if cc.has_function(b)
    conf_data.set('HAVE___BUILTIN_@0@'.format(b.to_upper()), 1)
  endif
endforeach

supported_function_attributes = cc.get_supported_function_attributes([
  'const', 'flatten', 'format', 'malloc', 'noreturn', 'packed', 'pure',
  'returns_nonnull', 'unused', 'warn_unused_result', 'weak',
])
foreach a : supported_function_attributes
    conf_data.set('HAVE_FUNC_ATTRIBUTE_@0@'.format(a.to_upper()), 1)
endforeach

foreach f : ['memfd_create', 'strtok_r', 'timespec_get']
  if cc.has_function(f)
    conf_data.set('HAVE_@0@'.format(f.to_upper()), 1)
  endif
endforeach

if host_machine.endian() == 'little'
  conf_data.set('UTIL_ARCH_LITTLE_ENDIAN', 1)
  conf_data.set('UTIL_ARCH_BIG_ENDIAN', 0)
elif host_machine.endian() == 'big'
  conf_data.set('UTIL_ARCH_LITTLE_ENDIAN', 0)
  conf_data.set('UTIL_ARCH_BIG_ENDIAN', 1)
else
  error('It wasn\'t possible to figure out the endianess of the machine')
endif

pipe_arch = host_machine.cpu_family()

if pipe_arch == 'x86'
  conf_data.set('PIPE_ARCH_X86', true)
elif pipe_arch == 'x86_64'
  conf_data.set('PIPE_ARCH_X86_64', true)
elif pipe_arch == 'ppc'
  conf_data.set('PIPE_ARCH_PPC', true)
elif pipe_arch == 'ppc64'
  conf_data.set('PIPE_ARCH_PPC_64', true)
elif pipe_arch == 's390x'
  conf_data.set('PIPE_ARCH_S390', true)
elif pipe_arch == 'arm'
  conf_data.set('PIPE_ARCH_ARM', true)
elif pipe_arch == 'aarch64'
  conf_data.set('PIPE_ARCH_AARCH64', true)
else
  warning('Arch used is not supported')
endif

if get_option('buildtype') == 'debug'
   add_project_arguments('-DDEBUG=1', language : 'c')
endif

platforms = get_option('platforms')

require_egl = platforms.contains('egl')
require_glx = platforms.contains('glx')
auto_egl_glx = platforms.contains('auto')

with_egl = require_egl or auto_egl_glx
with_glx = require_glx or auto_egl_glx

have_egl = false
have_glx = false

with_minigbm_allocation = get_option('minigbm_allocation')
if with_minigbm_allocation
   assert(not with_host_windows, 'minigbm allocation is not supported by windows host')
   conf_data.set('ENABLE_MINIGBM_ALLOCATION', 1)
   _gbm_ver = '18.0.0'
else
   _gbm_ver = '0.0.0'
endif

if with_egl
   if cc.has_header('epoxy/egl.h', dependencies: epoxy_dep) and epoxy_dep.get_variable(pkgconfig: 'epoxy_has_egl') == '1'
      if with_host_windows
         have_egl = true
      else
         if libdrm_dep.found()
            gbm_dep = dependency('gbm', version: '>= ' + _gbm_ver, required: require_egl)
         endif
         have_egl = gbm_dep.found() and cc.has_header('sys/mman.h', required: require_egl)
         conf_data.set('ENABLE_GBM', have_egl)
      endif
      conf_data.set('HAVE_EPOXY_EGL_H', have_egl)
   else
      assert(not require_egl,
             'egl was explicitely requested but it is not supported by epoxy')
   endif
endif

if with_glx
   if cc.has_header('epoxy/glx.h', dependencies: epoxy_dep) and epoxy_dep.get_variable(pkgconfig: 'epoxy_has_glx') == '1'
      glx_dep = dependency('x11', required: require_glx)
      have_glx = glx_dep.found()
      conf_data.set('HAVE_EPOXY_GLX_H', 1)
   else
      assert(not require_glx,
             'glx was explicitely requested but it is not supported by epoxy')
   endif
endif

have_vla = not cc.has_header_symbol('stdlib.h', '__STDC_NO_VLA__')

# drm/msm support requires the compiler to support VLA:
with_drm_msm = have_vla and get_option('drm-msm-experimental')
if with_drm_msm
  conf_data.set('ENABLE_DRM_MSM', 1)
endif
with_drm = with_drm_msm

with_check_gl_errors = get_option('check-gl-errors')
if with_check_gl_errors
   conf_data.set('CHECK_GL_ERRORS', 1)
endif

with_venus = get_option('venus')
with_render_server = with_venus
with_render_server_worker = get_option('render-server-worker')
render_server_install_dir = get_option('prefix') / get_option('libexecdir')
if with_venus
   if with_minigbm_allocation
      gbm_dep = dependency('gbm')
   endif
   venus_dep = dependency('vulkan')

   conf_data.set('ENABLE_VENUS', 1)

   if get_option('venus-validate')
      conf_data.set('ENABLE_VENUS_VALIDATE', 1)
   endif

   conf_data.set('ENABLE_RENDER_SERVER', 1)
   conf_data.set('RENDER_SERVER_EXEC_PATH',
                 '"' + render_server_install_dir / 'virgl_render_server' + '"')
   if meson.version().version_compare('>= 0.58')
      devenv = environment()
      devenv.append('RENDER_SERVER_EXEC_PATH',
                    meson.current_build_dir() / 'server/virgl_render_server')
      meson.add_devenv(devenv)
   else
      warning('set RENDER_SERVER_EXEC_PATH env if not install')
   endif

   if with_render_server_worker == 'process'
      conf_data.set('ENABLE_RENDER_SERVER_WORKER_PROCESS', 1)
   elif with_render_server_worker == 'thread'
      if not has_attribute_cleanup
         error('render-server-worker=thread requires __attribute__((cleanup))')
      endif
      conf_data.set('ENABLE_RENDER_SERVER_WORKER_THREAD', 1)
   elif with_render_server_worker == 'minijail'
      conf_data.set('ENABLE_RENDER_SERVER_WORKER_MINIJAIL', 1)
      minijail_dep = dependency('libminijail')
   else
     error('unknown render server worker ' + with_render_server_worker)
   endif
endif

with_video = get_option('video')
if with_video
  conf_data.set('ENABLE_VIDEO', 1)
  libva_dep = dependency('libva')
  libvadrm_dep = dependency('libva-drm')
endif

configure_file(input : 'config.h.meson',
               output : 'config.h',
               configuration : conf_data)

add_project_arguments('-imacros', meson.current_build_dir() / 'config.h', language : 'c')
add_project_arguments('-DHAVE_CONFIG_H=1', language : 'c')

inc_configuration = include_directories(['.', 'src'])

with_fuzzer = get_option('fuzzer')
with_tests = get_option('tests')
with_valgrind = get_option('valgrind')

with_unstable_apis = get_option('unstable-apis')
if with_unstable_apis
  pkg_cflags += '-DVIRGL_RENDERER_UNSTABLE_APIS=1'
endif

subdir('src')
if not with_host_windows
   subdir('vtest')
endif

if with_render_server
subdir('server')
endif

if with_tests
   assert(have_egl, 'Tests require EGL, but it is not available')
   subdir('tests')
endif

summary({'prefix': get_option('prefix'),
        'libdir': get_option('libdir'),
        }, section: 'Directories')
summary({'c_args': (' ').join(get_option('c_args')),
        'egl': have_egl,
        'glx': have_glx,
        'gbm': gbm_dep.found(),
        'minigbm_alloc': with_minigbm_allocation,
        'venus': with_venus,
        'drm-msm': with_drm_msm,
        'render server (DEPRECATED)': with_render_server,
        'render server worker': with_render_server ? with_render_server_worker : 'none',
        'video': with_video,
        'tests': with_tests,
        'fuzzer': with_fuzzer,
        'tracing': with_tracing,
        'unstable-apis': with_unstable_apis,
        }, section: 'Configuration')
