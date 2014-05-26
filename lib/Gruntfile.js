var commander = require('commander'),
    hostname = '0.0.0.0',
    port = 7777,
    mxmlcOpts = ' -optimize=true -show-actionscript-warnings=true -static-link-runtime-shared-libraries=true';

commander
    .option('-p, --port [type]', 'To specify a server port number(default: 7777)')
    .parse(process.argv);

port = commander.port || 7777;

module.exports = function(grunt) {
    grunt.initConfig({
        dirs: {
            root: '..',
            src: '../src',
            dist: '../dist',
            test: '../test',
            tmp: '../tmp',
            doc: '../doc',
            css: '../src/css',
            img: '../src/img',
            js: '../src/js',
            as: '../src/as'
        },

        jshint: {
            options: {
                curly: true,
                eqeqeq: true,
                immed: true,
                latedef: true,
                newcap: true,
                noarg: true,
                sub: true,
                boss: true,
                eqnull: true,
                node: true,
                es3: true,
                strict: false,
                unused: true,
                quotmark: 'single',
                laxbreak: true,
                browser: true
            },
            files: [
                'Gruntfile.js'
            ]
        },

        connect: {
            server: {
                options: {
                    hostname: hostname,
                    port: port,
                    base: ['<%= dirs.test %>', '<%= dirs.doc %>'],
                    keepalive: true
                }
            }
        },

        coffee: {
            src: {
                expand: true,
                options: {
                    bare: true
                },
                cwd: '<%= dirs.js %>',
                src: '**/*.coffee',
                dest: '<%= dirs.tmp %>/js',
                ext: '.js'
            },
            test: {
                expand: true,
                cwd: '<%= dirs.test %>',
                src: '**/*.coffee',
                dest: '<%= dirs.test %>',
                ext: '.js'
            },
            doc: {
                options: {
                    bare: true
                },
                src: '<%= dirs.js %>/player.coffee',
                dest: '<%= dirs.tmp %>/js/player.js'
            }
        },

        compass: {
            tmp: {
                options: {
                    sassDir: '<%= dirs.css %>',
                    cssDir: '<%= dirs.dist %>/css',
                    noLineComments: true
                }
            }
        },

        watch: {
            js: {
                files: [
                    'Gruntfile.js'
                ],
                tasks: ['jshint']
            },
            coffee: {
                files: [
                    '<%= dirs.js %>/**/*.coffee',
                    '<%= dirs.test %>/**/*.coffee'
                ],
                tasks: ['coffee:src']
            }
        },

        copy: {
            tmpjs: {
                expand: true,
                cwd: '<%= dirs.js %>/',
                src: '**/*.js',
                dest: '<%= dirs.tmp %>/js'
            },
            img: {
                expand: true,
                cwd: '<%= dirs.img %>/',
                src: '**/*',
                dest: '<%= dirs.dist %>/img'
            },
            mp3: {
                expand: true,
                cwd: '<%= dirs.src %>/mp3/',
                src: '**/*',
                dest: '<%= dirs.dist %>/mp3'
            },
            swf: {
                expand: true,
                cwd: '<%= dirs.src %>/swf/',
                src: '**/*',
                dest: '<%= dirs.dist %>/swf'
            },
            pc: {
                files: [
                    {
                        src: '<%= dirs.tmp %>/build/js/player.js',
                        dest: '<%= dirs.dist %>/js/player.js'
                    }
                ]
            },
            webapp: {
                files: [
                    {
                        src: '<%= dirs.tmp %>/build/js/player.js',
                        dest: '<%= dirs.dist %>/js/zepto-player.js'
                    }
                ]
            }
        },

        clean: {
            tmp: {
                options: {
                    force: true
                },
                src: [
                    '<%= dirs.tmp %>'
                ]
            },
            dist: {
                options: {
                    force: true
                },
                src: [
                    '<%= dirs.dist %>'
                ]
            },
            doc: {
                options: {
                    force: true
                },
                src: [
                    '<%= dirs.doc %>'
                ]
            }
        },

        requirejs: {
            pc: {
                options: {
                    appDir: '<%= dirs.tmp %>',
                    baseUrl: 'js/',
                    dir: '<%= dirs.tmp %>/build/',
                    optimize: 'none',
                    optimizeCss: 'standard',
                    modules: [
                        {
                            name: 'muplayer/player'
                        }
                    ],
                    fileExclusionRegExp: /^\./,
                    removeCombined: true,
                    wrap: {
                        startFile: '<%= dirs.src %>/license.txt'
                    },
                    pragmas: {
                        FlashCoreExclude: false
                    },
                    // HACK: 为了映射muplayer这个namespace
                    paths: {
                        'muplayer': '../js'
                    }
                }
            },
            webapp: {
                options: {
                    appDir: '<%= dirs.tmp %>',
                    baseUrl: 'js/',
                    dir: '<%= dirs.tmp %>/build/',
                    optimize: 'none',
                    optimizeCss: 'standard',
                    modules: [
                        {
                            name: 'muplayer/player'
                        }
                    ],
                    fileExclusionRegExp: /^\./,
                    removeCombined: true,
                    wrap: {
                        startFile: '<%= dirs.src %>/license.txt'
                    },
                    pragmas: {
                        FlashCoreExclude: true
                    },
                    paths: {
                        'muplayer': '../js'
                    }
                }
            }
        },

        uglify: {
            options: {
                report: 'min',
                preserveComments: 'some'
            },
            compress: {
                files: {
                    '<%= dirs.dist %>/js/player.min.js': '<%= dirs.dist %>/js/player.js',
                    '<%= dirs.dist %>/js/zepto-player.min.js': '<%= dirs.dist %>/js/zepto-player.js'
                }
            }
        },

        shell: {
            doc: {
                options: {
                    stderr: true
                },
                command: [
                    'doxx -R <%- dirs.root %>/README.md -t "MuPlayer 『百度音乐播放内核』" -s <%- dirs.tmp %>/js -T <%- dirs.doc %> --template <%- dirs.src %>/doc/base.jade',
                    'mv <%- dirs.doc %>/player.js.html <%- dirs.doc %>/api.html',
                    'cp <%- dirs.src %>/doc/**.html <%- dirs.doc %>',
                    'cp <%- dirs.img %>/favicon.ico <%- dirs.doc %>',
                    'ln -s <%- dirs.dist %> <%- dirs.doc %>/dist',
                    'ln -s <%- dirs.root %>/lib/bower_components <%- dirs.doc %>/bower_components'
                ].join('&&')
            },
            as: {
                options: {
                    stderr: true
                },
                command: [
                    'mxmlc -o <%- dirs.dist %>/swf/muplayer_mp3.swf <%- dirs.as %>/MP3Core.as' + mxmlcOpts
                ].join('&&')
            }
        },

        concat: {
            zepto: {
                src: ['<%= dirs.js %>/lib/zepto/*.js', '<%= dirs.dist %>/js/zepto-player.js'],
                dest: '<%= dirs.dist %>/js/zepto-player.js'
            }
        }
    });

    grunt.loadNpmTasks('grunt-shell');
    grunt.loadNpmTasks('grunt-contrib-connect');
    grunt.loadNpmTasks('grunt-contrib-coffee');
    grunt.loadNpmTasks('grunt-contrib-jshint');
    grunt.loadNpmTasks('grunt-contrib-compass');
    grunt.loadNpmTasks('grunt-contrib-watch');
    grunt.loadNpmTasks('grunt-contrib-copy');
    grunt.loadNpmTasks('grunt-contrib-clean');
    grunt.loadNpmTasks('grunt-contrib-requirejs');
    grunt.loadNpmTasks('grunt-contrib-uglify');
    grunt.loadNpmTasks('grunt-contrib-concat');

    grunt.registerTask('default', ['jshint', 'build', 'doc']);
    grunt.registerTask('server', ['connect:server']);
    grunt.registerTask('copy-to-dist', ['copy:img', 'copy:mp3', 'copy:swf']);
    grunt.registerTask('pc-js', ['requirejs:pc', 'copy:pc']);
    grunt.registerTask('webapp-js', ['requirejs:webapp', 'copy:webapp']);

    grunt.registerTask('build', ['copy:tmpjs', 'coffee', 'clean:dist', 'webapp-js', 'pc-js',
        'copy-to-dist', 'compass', 'shell:as', 'concat', 'uglify', 'clean:tmp']);
    grunt.registerTask('doc', ['clean:doc', 'compass', 'coffee:doc', 'shell:doc',
        'clean:tmp']);
};
