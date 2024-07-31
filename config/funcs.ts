import fs from "fs";

export  function writeAddress(filename:string, address:string) {
    if(!fs.existsSync("./addresses/presale")) {
      fs.mkdirSync("./addresses/presale", {recursive:true});
     } 
    
     const dirPath = "./addresses/presale";
    
     fs.writeFileSync(dirPath + filename + ".json", JSON.stringify({address: address}));
  
  }