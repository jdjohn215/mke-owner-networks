const config = {
  multipass: true,
  plugins: [
    {
      name: 'preset-default',
      params: {
        overrides: {
          // `minifyStyles` is disabled since it in combination with `convertShapeToPath`
          // causes paths to be drawn as one wide line rather than multiple individual lines
          minifyStyles: false
        },
      },
    },
  ],
};

module.exports = config;
