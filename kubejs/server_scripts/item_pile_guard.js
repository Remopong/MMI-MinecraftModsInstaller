// Garde-fou anti-tas d'objets au sol (ajouté le 13/11/2026).
// Un ventilateur Create qui tourne à l'envers maintenait 48 000 objets sur un seul bloc :
// le souffle remet leur âge à zéro donc ils ne despawn jamais, et le serveur finit par geler.
// Toutes les minutes, si plus de ITEM_PILE_LIMIT objets sont sur le même bloc, on les supprime
// et on note les coordonnées dans le log pour aller réparer la machine.
const ITEM_PILE_LIMIT = 1000
const ITEM_PILE_CHECK_TICKS = 1200
let itemPileGuardFirstRun = true

ServerEvents.tick(event => {
    const server = event.server
    if (server.getTickCount() % ITEM_PILE_CHECK_TICKS !== 0) return
    try {
        let scanned = 0
        server.getAllLevels().forEach(level => {
            const piles = {}
            level.getAllEntities().forEach(ent => {
                if (ent == null || String(ent.getEncodeId()) !== 'minecraft:item') return
                scanned++
                const key = ent.getBlockX() + ' ' + ent.getBlockY() + ' ' + ent.getBlockZ()
                if (!piles[key]) piles[key] = []
                piles[key].push(ent)
            })
            Object.keys(piles).forEach(key => {
                const list = piles[key]
                if (list.length <= ITEM_PILE_LIMIT) return
                list.forEach(ent => ent.discard())
                console.warn('[ItemPileGuard] ' + list.length + ' objets au sol supprimés en ' + key +
                    ' (' + level.dimension().location() + ') - vérifier la machine à cet endroit')
            })
        })
        if (itemPileGuardFirstRun) {
            itemPileGuardFirstRun = false
            console.info('[ItemPileGuard] actif : ' + scanned + ' objets au sol analysés')
        }
    } catch (err) {
        console.error('[ItemPileGuard] erreur : ' + err)
    }
})
