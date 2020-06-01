export default {
  input: "src/heyoffline.js",
  output: [
    {
      file: "dist/heyoffline.cjs.js",
      format: "cjs"
    },
    {
      file: "dist/heyoffline.umd.js",
      format: "umd",
      name: "Heyoffline"
    },
    {
      file: "dist/heyoffline.esm.js",
      format: "esm"
    }
  ]
};