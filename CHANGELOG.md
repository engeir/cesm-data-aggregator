# Changelog

## [1.0.2](https://github.com/engeir/cesm-data-aggregator/compare/v1.0.1...v1.0.2) (2024-09-04)


### Miscellaneous

* **usage:** start building simple usage CLI ([9b9fbf8](https://github.com/engeir/cesm-data-aggregator/commit/9b9fbf8397b85dce3dabaeab7d86d209407a3fa5))
* **usage:** update name of the CLI ([987d63a](https://github.com/engeir/cesm-data-aggregator/commit/987d63a91160dd28978fad52262c42822e94635d))


### Documentation

* **zenodo:** add a zenodo config ([8cebc44](https://github.com/engeir/cesm-data-aggregator/commit/8cebc44100fe8459c82eb37fc3e1c79182aa1ed6))

## [1.0.1](https://github.com/engeir/cesm-data-aggregator/compare/v1.0.0...v1.0.1) (2024-01-22)


### Code Refactoring

* **sc2086:** rewrite options from string to array ([3c36f44](https://github.com/engeir/cesm-data-aggregator/commit/3c36f44a9bb5f88b3d578ff68ed1b7cd32604cbf))


### Continuous Integration

* **github:** use my bot to create releases ([e15f932](https://github.com/engeir/cesm-data-aggregator/commit/e15f932954c402ec799945dd579348b13fceac08))

## 1.0.0 (2023-12-11)


### ⚠ BREAKING CHANGES

* generate can now extend using special "latest" value

### Features

* check if extended file and input files overlap in time ([3b2b95e](https://github.com/engeir/cesm-data-aggregator/commit/3b2b95e76e52f32057808a05d57d86d35aa06bc6))
* check if input files can be found ([4c21285](https://github.com/engeir/cesm-data-aggregator/commit/4c212852c8606e3de4942872f1cf86fce0452336))
* **gen_agg_nco:** skip existing files and print creating file note ([f70778f](https://github.com/engeir/cesm-data-aggregator/commit/f70778f1e40d47bb5877a2eaaeb02cc439946261))
* **gen_agg:** check if extend file exists ([10a9530](https://github.com/engeir/cesm-data-aggregator/commit/10a95304cfad4aed2b44d240336f997cec1037da))
* generate can now extend using special "latest" value ([51febab](https://github.com/engeir/cesm-data-aggregator/commit/51febab147242636f8ba7adec13715b42681e20e))
* initial commit ([57ddcf8](https://github.com/engeir/cesm-data-aggregator/commit/57ddcf860773baf09eec35c15f74eb120f0f0694))


### Bug Fixes

* check both first and second input file for time overlap ([3aad49b](https://github.com/engeir/cesm-data-aggregator/commit/3aad49b4bb24767b8e574cc5f04a396be9f0b13f))
* SST does not exist in h0 ([444101e](https://github.com/engeir/cesm-data-aggregator/commit/444101ee919ce1cb4687fbee76c5e08491d31776))
* use correct path and script name, and improve file save name ([808bb99](https://github.com/engeir/cesm-data-aggregator/commit/808bb99dc4a68557e38573739e43daf610c2b1d3))


### Miscellaneous

* add .gitignore ([7e4ef7b](https://github.com/engeir/cesm-data-aggregator/commit/7e4ef7b0be68040f995f0f8595243c3882b1decc))
* add comments about why we check the time twice ([9dc5a31](https://github.com/engeir/cesm-data-aggregator/commit/9dc5a31600a8cf9b17ff118b40d2e3c7e4c28559))
* do not exit sbatch on errors, I'll take my chances ([c262f74](https://github.com/engeir/cesm-data-aggregator/commit/c262f741d903ad1e8b1d3c197d0d5c58e68fe24a))
* update sbatch settings ([918804c](https://github.com/engeir/cesm-data-aggregator/commit/918804cdc219d5937c9868eb9e0c73a608c3d0c9))


### Styles

* surround variable with double-quotes ([f18b7d8](https://github.com/engeir/cesm-data-aggregator/commit/f18b7d8a7661d828a0c3309d5136230278fedbb3))


### Continuous Integration

* **github:** set up release-please workflow ([525176e](https://github.com/engeir/cesm-data-aggregator/commit/525176e9f040220e51afe00fcdce738dc367d787))


### Documentation

* **README:** create README.md ([24b0579](https://github.com/engeir/cesm-data-aggregator/commit/24b0579ce218ff0e41fd9c6aef97e5d8ec40a7e4))
