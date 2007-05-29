// Copyright (c) 2006-2007 Egon Willighagen <egonw@users.sf.net>
// Version: 20070102
//
// Released under the GPL license v2.
// http://www.gnu.org/copyleft/gpl.html

// Makes links to the PubChem database and the Google search engine
//
// useGoogle  = 0: do not make link
//              1: make link
// usePubChem = 0: do not make link
//              1: make link
function addGoogleAndPubChemLinks(useGoogle, usePubChem) {

        var allLinks, thisLink;
        
        // InChI support
        allLinks = document.evaluate(
                '//span[@class="chem:inchi" or @class="inchi"]',
                document, null, XPathResult.UNORDERED_NODE_SNAPSHOT_TYPE, null
        );
        for (var i = 0; i < allLinks.snapshotLength; i++) {
        thisLink = allLinks.snapshotItem(i);
        inchi = thisLink.innerHTML;
        // alert("Found InChI:" + inchi);
        
        if (usePubChem == 1) {
                // create a link to PubChem
                newElement = document.createElement('a');
                newElement.href = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?CMD=search&DB=pccompound&term=%22" + 
                inchi + " %22[InChI]";
                newElement.innerHTML = "<sup>PubChem</sup>";
                thisLink.parentNode.insertBefore(newElement, thisLink.nextSibling);
        }
        if (usePubChem == 1 && useGoogle == 1) {
                spacer = document.createElement('sup');
                spacer.innerHTML = ", ";
                thisLink.parentNode.insertBefore(spacer, thisLink.nextSibling);
        }
        if (useGoogle == 1) {
                // create a link to PubChem
                newElement = document.createElement('a');
                newElement.href = "http://www.google.com/search?q=" + inchi.substring(6);
                newElement.innerHTML = "<sup>Google</sup>";
                thisLink.parentNode.insertBefore(newElement, thisLink.nextSibling);
        }
        }
        
        // SMILES support
        allLinks = document.evaluate(
                '//span[@class="chem:smiles" or @class="smiles"]',
                document, null, XPathResult.UNORDERED_NODE_SNAPSHOT_TYPE, null
        );
        for (var i = 0; i < allLinks.snapshotLength; i++) {
        thisLink = allLinks.snapshotItem(i);
        smiles = thisLink.innerHTML;
        // alert("Found SMILES:" + smiles);
        
        if (usePubChem == 1) {
                // create a link to PubChem
                newElement = document.createElement('a');
                newElement.href = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?CMD=search&DB=pccompound&term=" + 
                smiles;
                newElement.innerHTML = "<sup>PubChem</sup>";
                thisLink.parentNode.insertBefore(newElement, thisLink.nextSibling);
        }
        if (usePubChem == 1 && useGoogle == 1) {
                spacer = document.createElement('sup');
                spacer.innerHTML = ", ";
                thisLink.parentNode.insertBefore(spacer, thisLink.nextSibling);
        }
        if (useGoogle == 1) {
                // create a link to PubChem
                newElement = document.createElement('a');
                newElement.href = "http://www.google.com/search?q=" + smiles;
                newElement.innerHTML = "<sup>Google</sup>";
                thisLink.parentNode.insertBefore(newElement, thisLink.nextSibling);
        }
        }
        
        // CAS regisitry number support
        allLinks = document.evaluate(
                '//span[@class="chem:casnumber" or @class="casnumber"]',
                document, null, XPathResult.UNORDERED_NODE_SNAPSHOT_TYPE, null
        );
        for (var i = 0; i < allLinks.snapshotLength; i++) {
        thisLink = allLinks.snapshotItem(i);
        casnumber = thisLink.innerHTML;
        // alert("Found CAS registry number:" + casnumber);
        
        if (useGoogle == 1) {
                // create a link to PubChem
                newElement = document.createElement('a');
                newElement.href = "http://www.google.com/search?q=" + casnumber + "+CAS";
                newElement.innerHTML = "<sup>Google</sup>";
                thisLink.parentNode.insertBefore(newElement, thisLink.nextSibling);
        }
        }
        
        // 'compound' support
        allLinks = document.evaluate(
                '//span[@class="chem:compound"]',
                document, null, XPathResult.UNORDERED_NODE_SNAPSHOT_TYPE, null
        );
        for (var i = 0; i < allLinks.snapshotLength; i++) {
        thisLink = allLinks.snapshotItem(i);
        smiles = thisLink.innerHTML;
        // alert("Found SMILES:" + smiles);
        
        if (usePubChem == 1) {
                // create a link to PubChem
                newElement = document.createElement('a');
                newElement.href = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?CMD=search&DB=pccompound&term=" + 
                smiles;
                newElement.innerHTML = "<sup>PubChem</sup>";
                thisLink.parentNode.insertBefore(newElement, thisLink.nextSibling);
        }
        }

}

