import unittest
from unittest.mock import patch
import os
import sys
sys.path.append('.')
import FileSwitcher as fs

# How to execute: py3f TestFileSwitcher.py

class TestFileSwitcher(unittest.TestCase):

    def setUp(self):
        self.temp_files = []

    def tearDown(self):
        if os.path.exists('tags'):
            os.remove('tags')
        for file in self.temp_files:
            if os.path.exists(file):
                os.remove(file)

    def _create_file(self, path):
        self.temp_files.append(path)
        with open(path, 'w') as file:
            file.write("Test file")

    def _add_text_to_tags(self, txt):
        with open('tags', 'a') as file:
            file.write(txt + "\n")

    def test_file_extension(self):
        self.assertEqual('cpp', fs.file_extension('foo.cpp'))
        self.assertEqual('hpp', fs.file_extension('foo.hpp'))

    @patch('vim.command')
    def test_print_error(self, mock_method):
        str = "test Eero error"
        fs.print_error(str)
        mock_method.assert_called_with('echomsg "test Eero error"')

    def test_get_files_from_tags(self):
        self._add_text_to_tags("!_TAG_PROGRAM_NAME\tUniversal Ctags /Derived from Exuberant Ctags/")
        self._add_text_to_tags("!_TAG_PROGRAM_URL\thttps://ctags.io/\t/official site/")
        self._add_text_to_tags("!_TAG_PROGRAM_VERSION\t6.0.0\t//")
        self._add_text_to_tags("AATRBL_MAX_FILE_SIZE_IN_BYTES\t./app/ctrl/rt/ru/aaTrblClientLogHandler/common/AaTrblClientUtils.hpp\t/^inline constexpr uint32_t AATRBL_MAX_FILE_SIZE_IN_BYTES           = 6 * 1000 * 1000;$/;\"\tv\tnamespace:l1sw::aaTrblClientLogHandler\ttyperef:typename:uint32_t")
        self._add_text_to_tags("AATRBL_MAX_NBR_OF_RETRIES\t./app/ctrl/rt/ru/aaTrblClientLogHandler/common/AaTrblClientUtils.hpp\t/^inline constexpr uint32_t AATRBL_MAX_NBR_OF_RETRIES               = 3;$/;\"\tv\tnamespace:l1sw::aaTrblClientLogHandler\ttyperef:typename:uint32_t")
        self._add_text_to_tags("AATRBL_MAX_NBR_OF_SPLIT_FILES\t./app/ctrl/rt/ru/aaTrblClientLogHandler/common/AaTrblClientUtils.hpp\t/^inline constexpr uint32_t AATRBL_MAX_NBR_OF_SPLIT_FILES           = 100;$/;\"\tv\tnamespace:l1sw::aaTrblClientLogHandler\ttyperef:typename:uint32_t")
        files = fs.get_files_from_tags()
        self.assertEqual(1, len(files))
        self.assertEqual(['./app/ctrl/rt/ru/aaTrblClientLogHandler/common/AaTrblClientUtils.hpp'], files)

    def test_find_files_in_tags(self):
        self.assertEqual(list(), fs.find_files_in_tags('Foo.cpp'))
        self.assertTrue(0 == len(fs.find_files_in_tags('Foo.cpp')))

    def test_find_files_in_tags1(self):
        self._add_text_to_tags("Main\tsoftware/bar/Foo.cpp\tclass Foo")
        self.assertEqual(['software/bar/Foo.cpp'], fs.find_files_in_tags('Foo.cpp'))

    def test_find_files_in_tags2(self):
        self._add_text_to_tags("Main\tsoftware/bar/TestFoo.cpp\tclass Foo")
        self._add_text_to_tags("Main\tsoftware/bar/Foo.cpp\tclass Foo")
        self.assertEqual(['software/bar/Foo.cpp'], fs.find_files_in_tags('software/foo/Foo.cpp'))

    def test_find_files_in_tags3(self):
        self._add_text_to_tags("Main\tsoftware/tmp/Foo.cpp\tclass Foo")
        self._add_text_to_tags("Main\tsoftware/bar/TestFoo.cpp\tclass Foo")
        self._add_text_to_tags("Main\tsoftware/bar/Foo.cpp\tclass Foo")
        self._add_text_to_tags("Main\tsoftware/sys/Foo.cpp\tclass Foo")
        files = fs.find_files_in_tags('software/foo/Foo.cpp')
        for file in ['software/tmp/Foo.cpp', 'software/sys/Foo.cpp', 'software/bar/Foo.cpp']:
            if file not in files:
                self.fail(f'File {file} cannot be found from files: {files}')

    @patch('vim.command')
    def test_open_file(self, mock_method):
        fs.open_file('stub/foo.cpp')
        mock_method.assert_called_with('edit stub/foo.cpp')

    def test_get_other_file(self):
        self.assertEqual('Foo.hpp', fs.get_other_file('Foo.cpp'))
        self.assertEqual('Foo.cpp', fs.get_other_file('Foo.hpp'))
        self.assertEqual('Foo.h', fs.get_other_file('Foo.c'))
        self.assertEqual('Foo.c', fs.get_other_file('Foo.h'))
        self.assertEqual('/tmp/bar/Foo.h', fs.get_other_file('/tmp/bar/Foo.c'))
        self.assertEqual('/tmp/bar/Foo.hpp', fs.get_other_file('/tmp/bar/Foo.cpp'))
        self.assertEqual(None, fs.get_other_file('/tmp/bar/Foo.py'))

    @patch('FileSwitcher.get_current_buffer_name')
    def test_get_files_none(self, mock_method):
        mock_method.return_value = 'Foo.cpp'
        self.assertEqual([], fs.get_files())

    @patch('FileSwitcher.get_current_buffer_name')
    def test_get_files_file_exists_hpp(self, mock_method):
        self._create_file("Foo.hpp")
        mock_method.return_value = 'Foo.cpp'
        self.assertEqual(['Foo.hpp'], fs.get_files())

    @patch('FileSwitcher.get_current_buffer_name')
    def test_get_files_file_exists_cpp(self, mock_method):
        self._create_file("Foo.cpp")
        mock_method.return_value = 'Foo.hpp'
        self.assertEqual(['Foo.cpp'], fs.get_files())

    @patch('FileSwitcher.get_current_buffer_name')
    def test_get_files_file_exists_in_tags(self, mock_method):
        mock_method.return_value = 'Foo.hpp'
        self._add_text_to_tags("Main\tsoftware/bar/Foo.cpp\tclass Foo")
        self.assertEqual(['software/bar/Foo.cpp'], fs.get_files())

unittest.main()
