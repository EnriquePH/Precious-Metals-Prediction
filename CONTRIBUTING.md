# Guía de contribución / Contributing

Gracias por interesarte en contribuir a este proyecto. Puedes contribuir de varias maneras: reportando errores, proponiendo mejoras, o enviando cambios por medio de pull requests.

Pasos rápidos para contribuir:

- Reportar un bug: abre un issue usando la plantilla **Bug report** y proporciona pasos reproducibles y tu información de sesión de R.
- Proponer una mejora: abre un issue usando la plantilla **Feature request** describiendo el caso de uso y la propuesta.
- Enviar código: haz un fork, crea una rama descriptiva (`fix/..., feat/...`), añade tests en `tests/testthat/`, ejecuta los checks locales y abre un PR.

Requisitos técnicos y estilo:

- Tests: añade pruebas en `tests/testthat/`. Ejecuta:

```r
Rscript -e "testthat::test_dir('tests/testthat', reporter='summary')"
```

- Linting y estilo: usamos `lintr` con configuración en `.lintr` (4 espacios y comillas simples). Ejecuta:

```r
Rscript -e "lintr::lint_dir('.')"
```

- R CMD check: antes de abrir un PR, ejecuta:

```sh
R CMD check --no-manual --as-cran
```

- Mensajes de commit: usa un formato claro y conciso. Prefijo sugerido: `fix:`, `feat:`, `docs:`, `test:`, `ci:`.

Checklist para PRs:

- [ ] El cambio tiene tests o justificación si no aplica.
- [ ] `lintr::lint_dir()` pasa sin problemas.
- [ ] `R CMD check` no tiene errores (advertencias y notas documentadas).
- [ ] Descripción del cambio y cómo probarlo añadida al PR.

Si necesitas ayuda, abre un issue y con gusto te oriento.

Si quieres que revise o aplique cambios de estilo automáticamente, dímelo.
