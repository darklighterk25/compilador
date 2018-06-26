# Compilador

Proyecto para las materias de Compiladores I y Compiadores II de la carrera de Ingeniería en Sistemas Computacionales de la Universidad Autónoma de Aguascalientes.


### Instalación:

La totalidad del proyecto está escrito en el lenguaje de programación [Ruby](https://rubyinstaller.org).

Para crear la interfaz gráfica hicimos uso de la gema [FXRuby](https://github.com/larskanis/fxruby):
```
gem install fxruby
```
El analizador sintáctico implementa la gema [RubyTree](https://github.com/evolve75/RubyTree):
```
gem install rubytree
```

### Ejecución:

```
ruby main.rb
```

### Directorios:

#### ide/
> Entorno gráfico.  

#### lexical_analyzer/
> Analizador léxico.

#### semantic_analyzer/
> Analizador semántico.

#### syntax_analyzer/
> Analizador sintáctico.
