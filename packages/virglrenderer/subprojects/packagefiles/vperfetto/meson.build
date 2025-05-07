# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

project(
    'vperfetto',
    ['cpp'],
    default_options: ['cpp_std=c++17']
)

deps_vperfetto = [dependency('threads')]

lib_vperfetto_min = library(
    'vperfetto_min',
    'vperfetto-min.cpp',
    'perfetto.cc',
    dependencies: deps_vperfetto,
    install: true,
)

dep_vperfetto_min = declare_dependency(
    link_with: lib_vperfetto_min,
    include_directories: include_directories('.'),
)
meson.override_dependency('vperfetto_min', dep_vperfetto_min)
