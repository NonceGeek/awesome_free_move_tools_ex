
const MAX_U64_BIG_INT = BigInt(2 ** 64) - BigInt(1)

const MARKET_ADDRESS = '0x1deec95982be38fe32d02e0c3018a7c6730df74c71b838f40aebcc6d48f6472b'
const MARKET_COINT_TYPE = '0x1::aptos_coin::AptosCoin'
const MARKET_NAME = 'move_nft_free_minter'

// const getAptosWallet = () => {
//   if ('aptos' in window) {
//       return window.aptos;
//   } else {
//       window.open('https://petra.app/', `_blank`);
//   }
// }

export const Aptos = {
  mounted () {
    const message = 'This is a simple message'
    const nonce = '123'
    let account

    window.addEventListener('load', async () => {
      account = await connect()
    })

    window.addEventListener('phx:connect-petra', async () => {
      try {
        await window.aptos.connect()
        const response = await window.aptos.signMessage({
          message,
          nonce
        })

        console.log('response', response)
        const { address, signature } = response
        login(address, signature)
        account = response
      } catch (error) {
        console.log('Sign Message Error:', error)
      }
    })

    window.addEventListener('phx:mint-token', async (e) => {
      account = await connect()
      console.log('account', account)
      console.log('e.detail:', e.detail)

      const { name, image, description, collection_name, is_collection_created: isCollectionCreated } = e.detail

      if (!account || !collection_name || !name || !description || !image) return
      try {
        const address = account.address.toString()

        if (!isCollectionCreated) {
          await createCollection(collection_name)
        }

        const result = await window.aptos.signAndSubmitTransaction(
          createTokenPayload(collection_name, name, description, image, address)
        )

        this.pushEvent('mint-succeed', { hash: result.hash })
      } catch (error) {
        console.log('Error create NFT: ', error)
        this.pushEvent('mint-failed', {})
      } finally {
        console.log('finally')
      }
    })

    window.addEventListener('phx:create', async (e) => {
      const { creator, collection_name: collection, name, property_version: propertyVersion } = e.detail.token
      const { price, order_id: orderId } = e.detail

      const payload = {
        type: 'entry_function_payload',
        function: `${MARKET_ADDRESS}::marketplace::buy_token`,
        type_arguments: [MARKET_COINT_TYPE],
        arguments: [
          MARKET_ADDRESS,
          MARKET_NAME,
          creator,
          collection,
          name,
          `${propertyVersion}`,
          `${price}`,
          `${orderId}`
        ]
      }

      try {
        const result = await window.aptos.signAndSubmitTransaction(payload)

        this.pushEvent('buy-succeed', { hash: result.hash })
      } catch (error) {
        console.log('Error buy NFT: ', error)
      }
    })

    window.addEventListener('phx:buy-token', async (e) => {
      const { creator, collection_name: collection, name, property_version: propertyVersion } = e.detail.token
      const { price, order_id: orderId } = e.detail

      const payload = {
        type: 'entry_function_payload',
        function: `${MARKET_ADDRESS}::marketplace::buy_token`,
        type_arguments: [MARKET_COINT_TYPE],
        arguments: [
          MARKET_ADDRESS,
          MARKET_NAME,
          creator,
          collection,
          name,
          `${propertyVersion}`,
          `${price}`,
          `${orderId}`
        ]
      }

      try {
        const result = await window.aptos.signAndSubmitTransaction(payload)

        this.pushEvent('buy-succeed', { hash: result.hash })
      } catch (error) {
        console.log('Error buy NFT: ', error)
      }
    })

    window.addEventListener('phx:list-token', async (e) => {
      const { creator, collection_name: collection, name, property_version: propertyVersion } = e.detail.token
      const { price } = e.detail

      const payload = {
        type: 'entry_function_payload',
        function: `${MARKET_ADDRESS}::marketplace::list_token`,
        type_arguments: [MARKET_COINT_TYPE],
        arguments: [
          MARKET_ADDRESS,
          MARKET_NAME,
          creator,
          collection,
          name,
          `${propertyVersion}`,
          price
        ]
      }

      console.log('payload:', payload)

      try {
        const result = await window.aptos.signAndSubmitTransaction(payload)

        this.pushEvent('list-succeed', { hash: result.hash })
      } catch (error) {
        console.log('Error list NFT: ', error)
      }
    })
  }
}

async function createCollection (collection) {
  await window.aptos.signAndSubmitTransaction(
    createCollectionPayload(
      collection,
      'created by MoveDID',
      'https://github.com/NonceGeek/MoveDID'
    )
  )
}

function createCollectionPayload (name, description, uri, num) {
  return {
    type: 'entry_function_payload',
    function: '0x3::token::create_collection_script',
    type_arguments: [],
    arguments: [
      name,
      description,
      uri,
      MAX_U64_BIG_INT.toString(),
      [false, false, false]
    ]
  }
}

function createTokenPayload (
  collection,
  name,
  description,
  uri,
  royaltyPayee
) {
  return {
    type: 'entry_function_payload',
    function: '0x3::token::create_token_script',
    type_arguments: [],
    arguments: [
      collection,
      name,
      description,
      '1',
      MAX_U64_BIG_INT.toString(),
      uri,
      royaltyPayee,
      100,
      0,
      [false, false, false, false, false],
      [],
      [],
      []
    ]
  }
}

async function connect () {
  const isConnected = await window.aptos.isConnected()
  console.log('isConnected:', isConnected)

  if (isConnected) {
    const account = await window.aptos.account()
    return account
  }
  // } else {
  //   const account = await window.aptos.connect()
  //   const { address } = account
  //   login(address)
  //   return account
  // }
}

function login (address, signature) {
  const form = document.createElement('form')
  const element0 = document.createElement('input')
  const element1 = document.createElement('input')
  const element2 = document.createElement('input')

  const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute('content')

  form.method = 'POST'
  form.action = '/auth'

  element0.name = '_csrf_token'
  element0.value = csrfToken
  form.appendChild(element0)

  element1.name = 'wallet_address'
  element1.value = address
  form.appendChild(element1)

  element2.name = 'signature'
  element2.value = signature
  form.appendChild(element2)

  document.body.appendChild(form)

  form.submit()
}
